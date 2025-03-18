*** Settings ***
Suite Setup     Setup
Suite Teardown  Teardown
Test Teardown   Test Teardown
Resource        ${RENODEKEYWORDS}

*** Variables ***
${desired_period_clks}  {{PERIODCLKS}}
${desired_duty_cycle_clks}  {{DUTYCLKS}}
${simulation_cycles}  {{SIMCYCLES}}

*** Keywords ***
Create Nucleo Board
    
    Execute Command          include @${CURDIR}/STM32F3_RCC.cs
    Execute Command          include @${CURDIR}/STM32F3_EXTI.cs
    Execute Command          include @${CURDIR}/STM32F3_FlashController.cs

    Execute Command          $bin = @${CURDIR}/build/stm32-pwm.elf

    Execute Command  using sysbus
    Execute Command  mach create "STM32F334R8-Nucleo"
    Execute Command  machine LoadPlatformDescription @${CURDIR}/stm32f334R8_nucleo.repl

    Execute Command  sysbus LoadELF $bin

    Create LED Tester        sysbus.gpioPortA.UserLED  defaultTimeout=2


*** Test Cases ***

#LED Tester Assert Is Blinking Should Precisely Pause Emulation
#    [Tags]                   instructions_counting
#    Create Nucleo Board
#
#    Assert LED Is Blinking   testDuration=5  onDuration=1  offDuration=1  pauseEmulation=true

LED Tester Assert Duty Cycle Should Precisely Pause Emulation
    [Tags]                   instructions_counting
    Create Nucleo Board

    Assert LED Duty Cycle    testDuration=0.001  expectedDutyCycle=0.25  tolerance=0
