//
// Copyright (c) 2010-2024 Antmicro
// Copyright (c) 2025-2025 Vogt
//
//  This file is licensed under the MIT License.
//  Full license text is available in 'licenses/MIT.txt'.
//
using System;
using System.Linq;
using System.Collections.Generic;
using Antmicro.Renode.Core;
using Antmicro.Renode.Core.Structure.Registers;
using Antmicro.Renode.Logging;
using Antmicro.Renode.Logging.Profiling;
using Antmicro.Renode.Peripherals.Bus;
using Antmicro.Renode.Peripherals.CPU;
using Antmicro.Renode.Peripherals.Memory;
using Antmicro.Renode.Utilities;

namespace Antmicro.Renode.Peripherals.MTD
{
    [AllowedTranslations(AllowedTranslation.ByteToDoubleWord | AllowedTranslation.WordToDoubleWord)]
    public class STM32F3_FlashController : STM32_FlashController, IKnownSize
    {
        public STM32F3_FlashController(IMachine machine, MappedMemory flash) : base(machine)
        {
            this.flash = flash;

            controlLock = new LockRegister(this, nameof(controlLock), ControlLockKey);
            optionControlLock = new LockRegister(this, nameof(optionControlLock), OptionLockKey);

            optionBytesRegisters = new DoubleWordRegisterCollection(this);

            DefineRegisters();
            Reset();
        }

        public override void Reset()
        {
            base.Reset();
            controlLock.Reset();
            optionControlLock.Reset();
        }

        [ConnectionRegion("optionBytes")]
        public uint ReadDoubleWordFromOptionBytes(long offset)
        {
            uint value = optionBytesRegisters.Read(offset);
            this.Log(LogLevel.Debug, "Reading from option bytes (offset: 0x{0:X} value: 0x{1:X8})", offset, value);
            return value;
        }

        [ConnectionRegion("optionBytes")]
        public void WriteDoubleWordToOptionBytes(long offset, uint value)
        {
            // This region is modified by using the OptionControl register. Direct modification is not allowed
            this.Log(LogLevel.Error, "Attempt to write 0x{0:X8} to {1} in the option bytes region", value, offset);
        }

        public override void WriteDoubleWord(long offset, uint value)
        {
            if ((Registers)offset == Registers.Control && controlLock.IsLocked)
            {
                this.Log(LogLevel.Warning, "Attempted to write 0x{0:X8} to a locked Control register. Ignoring...", value);
                return;
            }

            if ((Registers)offset == Registers.Option && optionControlLock.IsLocked)
            {
                this.Log(LogLevel.Warning, "Attempted to write 0x{0:X8} to a locked Option register. Ignoring...", value);
                return;
            }

            base.WriteDoubleWord(offset, value);
        }

        public long Size => 0x400;

        private void DefineRegisters()
        {
            Registers.AccessControl.Define(this)
                //This field is written and read by software and we need to keep it's value.
                .WithValueField(0, 3, name: "LATENCY")
                .WithTaggedFlag("HLFCYA", 3)
                .WithTaggedFlag("PRFTBE", 4)
                .WithTaggedFlag("PRFTBS", 5)
                .WithReservedBits(6, 26);

            Registers.Key.Define(this)
                .WithValueField(0, 32, FieldMode.Write, name: "FLASH_KEYR",
                    writeCallback: (_, value) => controlLock.ConsumeValue((uint)value));

            Registers.OptionKey.Define(this)
                .WithValueField(0, 32, FieldMode.Write, name: "FLASH_OPTKEYR",
                    writeCallback: (_, value) => optionControlLock.ConsumeValue((uint)value));

            Registers.Status.Define(this)
                .WithTaggedFlag("BSY", 0)
                .WithReservedBits(1, 1)
                .WithTaggedFlag("PGERR", 2)
                .WithReservedBits(3, 1)
                .WithTaggedFlag("WRPRTERR", 4)
                .WithTaggedFlag("EOP", 5)
                .WithReservedBits(6, 26);

            // Must be defined before Control register to access flashAddress.
            Registers.Address.Define(this)
            .WithValueField(0, 32, out var flashAddress, name: "FAR");

            Registers.Control.Define(this)
                .WithTaggedFlag("PG", 0)
                .WithFlag(1, out var pageErase, name: "PER")
                .WithFlag(2, out var massErase, name: "MER")
                .WithReservedBits(3, 1)
                .WithFlag(6, out var startErase, name: "STRT", mode: FieldMode.Read | FieldMode.Set, valueProviderCallback: _ => false)
                .WithFlag(7, FieldMode.Read | FieldMode.Set, name: "LOCK", valueProviderCallback: _ => controlLock.IsLocked,
                    changeCallback: (_, value) =>
                    {
                        if (value)
                        {
                            controlLock.Lock();
                        }
                    })
                .WithChangeCallback((_, __) =>
                {
                    if (startErase.Value)
                    {
                        Erase(massErase.Value, pageErase.Value, (uint)flashAddress.Value);
                    }
                })
                .WithReservedBits(8, 1)
                .WithTaggedFlag("OPTWRE", 9)
                .WithTaggedFlag("ERRIE", 10)
                .WithReservedBits(11, 1)
                .WithTaggedFlag("EOPIE", 12)
                .WithTaggedFlag("OBL_LAUNCH", 13)
                .WithReservedBits(14, 18);

            Registers.Option.Define(this, 0x00000000)
            .WithTaggedFlag("OPTERR", 0)
            .WithTag("RDPRT", 1, 2)
            .WithReservedBits(3, 5)
            .WithTaggedFlag("WDG_SW", 8)
            .WithTaggedFlag("nRST_STOP", 9)
            .WithTaggedFlag("nRST_STDBY", 10)
            .WithReservedBits(11, 1)
            .WithTaggedFlag("nBOOT1", 12)
            .WithTaggedFlag("VDDA_MONITOR", 13)
            .WithTaggedFlag("SRAM_PE.", 14)
            .WithReservedBits(15, 1)
            .WithValueField(16, 8, out var data0, name: "Data0")
            .WithValueField(24, 8, out var data1, name: "Data1");

            Registers.WriteProtect.Define(optionBytesRegisters, 0xFFFFFFFF)
                .WithTag("WRP", 0, 32);
        }

        private void Erase(bool massErase, bool pageErase, uint pageNumber)
        {
            if (!massErase && !pageErase)
            {
                this.Log(LogLevel.Warning, "Tried to erase flash, but MER and PER are reset. This should be forbidden, ignoring...");
                return;
            }

            if (massErase)
            {
                PerformMassErase();
            }
            else
            {
                PerformPageErase(pageNumber);
            }
        }

        private void PerformPageErase(uint pageNumber)
        {
            if (!Pages.ContainsKey(pageNumber))
            {
                this.Log(LogLevel.Warning, "Tried to erase page {0}, which doesn't exist. Ignoring...", pageNumber);
                return;
            }

            this.Log(LogLevel.Noisy, "Erasing page {0}, offset 0x{1:X}, size 0x{2:X}", pageNumber, Pages[pageNumber].Offset, Pages[pageNumber].Size);
            flash.WriteBytes(Pages[pageNumber].Offset, ErasePattern, Pages[pageNumber].Size);
        }

        private void PerformMassErase()
        {
            this.Log(LogLevel.Noisy, "Performing flash mass erase");
            foreach (var pageNumber in Pages.Keys)
            {
                PerformPageErase(pageNumber);
            }
        }

        private readonly MappedMemory flash;
        private readonly LockRegister controlLock;
        private readonly LockRegister optionControlLock;
        private readonly DoubleWordRegisterCollection optionBytesRegisters;

        private static readonly uint[] ControlLockKey = { 0x45670123, 0xCDEF89AB };
        private static readonly uint[] OptionLockKey = { 0x8192A3B, 0x4C5D6E7F };
        private static readonly byte[] ErasePattern = Enumerable.Repeat((byte)0xFF, MaxPageSize).ToArray();
        private static readonly Dictionary<uint, Page> Pages = new Dictionary<uint, Page>()
        {
            { 0, new Page { Offset = 0x00000000, Size = 0x4000 } },
            { 1, new Page { Offset = 0x00004000, Size = 0x4000 } },
            { 2, new Page { Offset = 0x00008000, Size = 0x4000 } },
            { 3, new Page { Offset = 0x0000C000, Size = 0x4000 } },
            { 4, new Page { Offset = 0x00010000, Size = 0x4000 } },
            { 5, new Page { Offset = 0x00020000, Size = 0x10000 } },
            { 6, new Page { Offset = 0x00040000, Size = 0x20000 } },
            { 7, new Page { Offset = 0x00060000, Size = 0x20000 } },
            { 8, new Page { Offset = 0x00080000, Size = 0x20000 } },
            { 9, new Page { Offset = 0x000A0000, Size = 0x20000 } },
            { 10, new Page { Offset = 0x000C0000, Size = 0x20000 } },
            { 11, new Page { Offset = 0x000E0000, Size = 0x20000 } },
        };

        private const int MaxPageSize = 0x20000;

        private class Page
        {
            public uint Offset { get; set; }
            public int Size { get; set; }
        }

        private enum Registers
        {
            AccessControl = 0x00,   // FLASH_ACR
            Key = 0x04,             // FLASH_KEYR
            OptionKey = 0x08,       // FLASH_OPTKEYR
            Status = 0x0C,          // FLASH_SR
            Control = 0x10,         // FLASH_CR
            Address = 0x14,         // FLASH_AR
            Option = 0x1C,   // FLASH_OBR
            WriteProtect = 0x20,   // FLASH_WRPR
        }
    }
}

