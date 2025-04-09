*** Settings ***
Resource            ${RENODEKEYWORDS}

Suite Setup         Setup
Suite Teardown      Teardown
Test Teardown       Test Teardown


*** Variables ***
${desired_period_clks}          {{PERIODCLKS}}
${desired_duty_cycle_clks}      {{DUTYCLKS}}
${simulation_cycles}            {{SIMCYCLES}}


*** Test Cases ***
LED Tester Assert Duty Cycle Should Precisely Pause Emulation
    [Tags]    sels
    Create Nucleo Board

    Assert LED Duty Cycle
    ...    testDuration=${simulation_cycles}
    ...    expectedDutyCycle=${${desired_duty_cycle_clks} / ${desired_period_clks}}
    ...    tolerance=${0.005}
    ...    pauseEmulation=true


*** Keywords ***
Create Nucleo Board
    Execute Command    include @${CURDIR}/STM32F3_RCC.cs
    Execute Command    include @${CURDIR}/STM32F3_EXTI.cs
    Execute Command    include @${CURDIR}/STM32F3_FlashController.cs

    Execute Command    $bin = @${CURDIR}/build/stm32-pwm.elf

    Execute Command    using sysbus
    Execute Command    mach create "STM32F334R8-Nucleo"
    Execute Command    machine LoadPlatformDescription @${CURDIR}/stm32f334R8_nucleo.repl

    Execute Command    sysbus LoadELF $bin

    Create LED Tester    sysbus.gpioPortA.UserLED    defaultTimeout=2
