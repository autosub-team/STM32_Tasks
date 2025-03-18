//
// Copyright (c) 2010-2020 Antmicro
// Copyright (c) 2025-2025 Vogt
//
//  This file is licensed under the MIT License.
//  Full license text is available in 'licenses/MIT.txt'.
//

using System;
using System.Collections.Generic;
using Antmicro.Renode.Core;
using Antmicro.Renode.Core.Structure.Registers;
using Antmicro.Renode.Peripherals.Bus;
using Antmicro.Renode.Peripherals.Timers;

namespace Antmicro.Renode.Peripherals.Miscellaneous
{
    [AllowedTranslations(AllowedTranslation.ByteToDoubleWord | AllowedTranslation.WordToDoubleWord)]
    public sealed class STM32F3_RCC : IDoubleWordPeripheral, IKnownSize, IProvidesRegisterCollection<DoubleWordRegisterCollection>
    {
        public STM32F3_RCC(IMachine machine, STM32F4_RTC rtcPeripheral)
        {
            // Renode, in general, does not include clock control peripherals.
            // While this is doable, it seldom benefits real software development
            // and is very cumbersome to maintain.
            //
            // To properly support the RTC peripheral, we need to add this stub class.
            // It is common in Renode that whenever a register is implemented, it
            // either contains actual logic or tags, indicating not implemented fields.
            //
            // Here, however, we want to fake most of the registers as r/w values.
            // Usually we implemented this logic with Python peripherals.
            //
            // Keep in mind that most of these registers do not affect other
            // peripherals or their clocks.
            var registersMap = new Dictionary<long, DoubleWordRegister>
            {
                {(long)Registers.ClockControl, new DoubleWordRegister(this, 0x083)
                    .WithFlag(0, out var hsion, name: "HSION")
                    .WithFlag(1, FieldMode.Read, valueProviderCallback: _ => hsion.Value, name: "HSIRDY")
                    .WithReservedBits(2, 1)
                    .WithValueField(3, 5, name: "HSITRIM")
                    .WithTag("HSICAL", 8, 8)
                    .WithFlag(16, out var hseon, name: "HSEON")
                    .WithFlag(17, FieldMode.Read, valueProviderCallback: _ => hseon.Value, name: "HSERDY")
                    .WithTag("HSEBYP", 18, 1)
                    .WithTag("CSSON", 19, 1)
                    .WithReservedBits(20, 4)
                    .WithFlag(24, out var pllon, name: "PLLON")
                    .WithFlag(25, FieldMode.Read, valueProviderCallback: _ => pllon.Value, name: "PLLRDY")
                    .WithReservedBits(26, 6)
                },
                {(long)Registers.ClockConfiguration, new DoubleWordRegister(this)
                    .WithValueField(0, 2, out var systemClockSwitch, name: "SW")
                    .WithValueField(2, 2, FieldMode.Read, name: "SWS", valueProviderCallback: _ => systemClockSwitch.Value)
                    .WithValueField(4, 4, name: "HPRE")
                    .WithValueField(8, 3, name: "PPRE1")
                    .WithValueField(11, 3, name: "PPRE2")
                    .WithReservedBits(14, 2)
                    .WithTag("PLLSRC", 16, 1)
                    .WithTag("PLLXTPRE", 17, 1)
                    .WithValueField(18, 4, name: "PLLMUL")
                    .WithReservedBits(22, 2)
                    .WithValueField(24, 3, name: "MCO")
                    .WithReservedBits(27, 1)
                    .WithValueField(28, 3, name: "MCOPRE")
                    .WithTag("PLLNODIV", 31, 1)
                },
                {(long)Registers.ClockInterrupt, new DoubleWordRegister(this)
                    .WithTag("LSIRDYF", 0, 1)
                    .WithTag("LSERDYF", 1, 1)
                    .WithTag("HSIRDYF", 2, 1)
                    .WithTag("HSERDYF", 3, 1)
                    .WithTag("PLLRDYF", 4, 1)
                    .WithReservedBits(5, 2)
                    .WithTag("CSSF", 7, 1)
                    .WithTag("LSIRDYIE", 8, 1)
                    .WithTag("LSERDYIE", 9, 1)
                    .WithTag("HSIRDYIE", 10, 1)
                    .WithTag("HSERDYIE", 11, 1)
                    .WithTag("PLLRDYIE", 12, 1)
                    .WithReservedBits(13, 3)
                    .WithTag("LSIRDYC", 16, 1)
                    .WithTag("LSERDYC", 17, 1)
                    .WithTag("HSIRDYC", 18, 1)
                    .WithTag("HSERDYC", 19, 1)
                    .WithTag("PLLRDYC", 20, 1)
                    .WithReservedBits(21, 2)
                    .WithTag("CSSC", 23, 1)
                    .WithReservedBits(24, 8)
                },
                {(long)Registers.APB2PeripheralReset, new DoubleWordRegister(this)
                    .WithValueField(0, 1, name: "SYSCFGRST")
                    .WithReservedBits(1, 9)
                    .WithValueField(11, 1, name: "TIM1RST")
                    .WithValueField(12, 1, name: "SPI1RST")
                    .WithReservedBits(13, 1)
                    .WithValueField(14, 1, name: "USART1RST")
                    .WithReservedBits(15, 1)
                    .WithValueField(16, 1, name: "TIM15RST")
                    .WithValueField(17, 1, name: "TIM16RST")
                    .WithValueField(18, 1, name: "TIM17RST")
                    .WithReservedBits(19, 10)
                    .WithValueField(29, 1, name: "HRTIM1RST")
                    .WithReservedBits(30, 2)
                },
                {(long)Registers.APB1PeripheralReset, new DoubleWordRegister(this)
                    .WithValueField(0, 1, name: "TIM2RST")
                    .WithValueField(1, 1, name: "TIM3RST")
                    .WithReservedBits(2, 2)
                    .WithValueField(4, 1, name: "TIM6RST")
                    .WithValueField(5, 1, name: "TIM7RST")
                    .WithReservedBits(6, 5)
                    .WithFlag(11, name: "WWDGRST")
                    .WithReservedBits(12, 4)
                    .WithValueField(17, 1, name: "USART2RST")
                    .WithValueField(18, 1, name: "USART3RST")
                    .WithReservedBits(19, 2)
                    .WithValueField(21, 1, name: "I2C1RST")
                    .WithReservedBits(22, 3)
                    .WithValueField(25, 1, name: "CANRST")
                    .WithFlag(26, name: "DAC2RST")
                    .WithReservedBits(27, 1)
                    .WithValueField(28, 1, name: "PWRRST")
                    .WithFlag(29, name: "DAC1RST")
                    .WithReservedBits(30, 2)
                },
                {(long)Registers.AHBPeripheralClockEnable, new DoubleWordRegister(this)
                    .WithValueField(0, 1, name: "DMA1EN")
                    .WithReservedBits(1, 1)
                    .WithValueField(2, 1, name: "SRAMEN")
                    .WithReservedBits(3, 1)
                    .WithValueField(4, 1, name: "FLITFEN")
                    .WithReservedBits(5, 1)
                    .WithValueField(6, 1, name: "CRCEN")
                    .WithReservedBits(7, 10)
                    .WithValueField(17, 1, name: "IOPAEN")
                    .WithValueField(18, 1, name: "IOPBEN")
                    .WithValueField(19, 1, name: "IOPCEN")
                    .WithValueField(20, 1, name: "IOPDEN")
                    .WithReservedBits(21, 1)
                    .WithValueField(22, 1, name: "IOPFEN")
                    .WithReservedBits(23, 1)
                    .WithValueField(24, 1, name: "TSCEN")
                    .WithReservedBits(25, 3)
                    .WithValueField(28, 1, name: "ADC12EN")
                    .WithReservedBits(29, 3)
                },
                {(long)Registers.APB2PeripheralClockEnable, new DoubleWordRegister(this)
                    .WithValueField(0, 1, name: "SYSCFGEN")
                    .WithReservedBits(1, 9)
                    .WithValueField(11, 1, name: "TIM1EN")
                    .WithValueField(12, 1, name: "SPI1EN")
                    .WithReservedBits(13, 1)
                    .WithValueField(14, 1, name: "USART1EN")
                    .WithReservedBits(15, 1)
                    .WithValueField(16, 1, name: "TIM15EN")
                    .WithValueField(17, 1, name: "TIM16EN")
                    .WithValueField(18, 1, name: "TIM17EN")
                    .WithReservedBits(19, 9)
                    .WithValueField(29, 1, name: "HRTIMER1EN")
                    .WithReservedBits(30, 2)

                },
                {(long)Registers.APB1PeripheralClockEnable, new DoubleWordRegister(this)
                    .WithValueField(0, 1, name: "TIM2EN")
                    .WithValueField(1, 1, name: "TIM3EN")
                    .WithReservedBits(2, 2)
                    .WithValueField(4, 1, name: "TIM6EN")
                    .WithValueField(5, 1, name: "TIM7EN")
                    .WithReservedBits(6, 5)
                    .WithFlag(11, name: "WWDGEN")
                    .WithReservedBits(12, 5)
                    .WithValueField(17, 1, name: "UART2EN")
                    .WithValueField(18, 1, name: "UART3EN")
                    .WithReservedBits(19, 2)
                    .WithValueField(21, 1, name: "I2C1EN")
                    .WithReservedBits(22, 3)
                    .WithValueField(25, 1, name: "CANEN")
                    .WithFlag(26, name: "DAC2EN")
                    .WithReservedBits(27, 1)
                    .WithFlag(28, name: "PWREN")
                    .WithFlag(29, name: "DAC1EN")
                    .WithReservedBits(30, 2)
                },
                {(long)Registers.RTCDomainControl, new DoubleWordRegister(this, 0x00000018)
                    .WithFlag(0, out var lseon, name: "LSEON")
                    .WithFlag(1, FieldMode.Read, valueProviderCallback: _ => lseon.Value, name: "LSERDY")
                    .WithFlag(2, name: "LSEBYP")
                    .WithTag("LSEDRV", 3, 2)
                    .WithReservedBits(5, 3)
                    .WithTag("RTCSEL", 8, 2)
                    .WithReservedBits(10, 5)
                    .WithFlag(15, name: "RTCEN",
                        writeCallback: (_, value) =>
                        {
                            if(value)
                            {
                                machine.SystemBus.EnablePeripheral(rtcPeripheral);
                            }
                            else
                            {
                                machine.SystemBus.DisablePeripheral(rtcPeripheral);
                            }
                        })
                    .WithTag("BDRST", 16, 1)
                    .WithReservedBits(17, 15)
                },
                {(long)Registers.ClockControlAndStatus, new DoubleWordRegister(this, 0x0C000000)
                    .WithFlag(0, out var lsion, name: "LSION")
                    .WithFlag(1, FieldMode.Read, valueProviderCallback: _ => lsion.Value, name: "LSIRDY")
                    .WithReservedBits(2, 21)
                    .WithTag("V18PWRRSTF", 23, 1)
                    .WithTag("RMVF", 24, 1)
                    .WithTag("OBLRSTF", 25, 1)
                    .WithTag("PINRSTF", 26, 1)
                    .WithTag("PORRSTF", 27, 1)
                    .WithTag("SFTRSTF", 28, 1)
                    .WithTag("IWDGRSTF", 29, 1)
                    .WithTag("WWDGRSTF", 30, 1)
                    .WithTag("LPWRRSTF", 31, 1)
                },
                {(long)Registers.AHBPeripheralReset, new DoubleWordRegister(this)
                    .WithReservedBits(0, 17)
                    .WithFlag(17, name: "IOPARST")
                    .WithFlag(18, name: "IOPBRST")
                    .WithFlag(19, name: "IOPCRST")
                    .WithFlag(20, name: "IOPDRST")
                    .WithReservedBits(21, 1)
                    .WithFlag(22, name: "IOPFRST")
                    .WithReservedBits(23, 1)
                    .WithFlag(24, name: "TSCRST")
                    .WithReservedBits(25, 3)
                    .WithFlag(28, name: "ADC12RST")
                    .WithReservedBits(29, 3)
                },
                {(long)Registers.ClockConfiguration2, new DoubleWordRegister(this)
                .WithTag("PREDIV", 0, 4)
                .WithTag("ADC12PRES", 4, 5)
                .WithReservedBits(9, 23)
                },
                {(long)Registers.ClockConfiguration3, new DoubleWordRegister(this)
                .WithTag("USART1SW", 0, 2)
                .WithReservedBits(2, 2)
                .WithTag("I2C1SW", 4, 1)
                .WithReservedBits(5, 3)
                .WithTag("TIM1SW", 8, 1)
                .WithReservedBits(9, 3)
                .WithTag("HRTIM1SW", 12, 1)
                .WithReservedBits(13, 19)
                },
            };

            RegistersCollection = new DoubleWordRegisterCollection(this, registersMap);
        }

        public uint ReadDoubleWord(long offset)
        {
            return RegistersCollection.Read(offset);
        }

        public void WriteDoubleWord(long offset, uint value)
        {
            RegistersCollection.Write(offset, value);
        }

        public void Reset()
        {
            RegistersCollection.Reset();
        }

        public long Size => 0x400;

        public DoubleWordRegisterCollection RegistersCollection { get; }

        private enum Registers
        {
            ClockControl = 0x0,
            ClockConfiguration = 0x4,
            ClockInterrupt = 0x8,
            APB2PeripheralReset = 0x0C,
            APB1PeripheralReset = 0x10,
            AHBPeripheralClockEnable = 0x14,
            APB2PeripheralClockEnable = 0x18,
            APB1PeripheralClockEnable = 0x1C,
            RTCDomainControl = 0x20,
            ClockControlAndStatus = 0x24,
            AHBPeripheralReset = 0x28,
            ClockConfiguration2 = 0x2C,
            ClockConfiguration3 = 0x30,

        }
    }
}

