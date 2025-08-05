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
Test for correct Duty Cycle
    [Tags]    sels
    Create Nucleo Board

    Execute Command          gpioPortA.pt Reset
    Execute Command          pause
    Execute Command          emulation RunFor "5"
    Start Emulation
    ${hp}=  Execute Command  gpioPortA.pt HighPercentage
    ${ht}=  Execute Command  gpioPortA.pt HighTicks
    ${hpn}=  HighPercentage To Number  ${hp}
    Should Be Equal Within Range  ${${desired_duty_cycle_clks} / ${desired_period_clks} * 100}  ${hpn}  1


*** Keywords ***
Create Nucleo Board
    Execute Command    include @${CURDIR}/renode/renode_stm32f3/STM32F3_RCC.cs
    Execute Command    include @${CURDIR}/renode/renode_stm32f3/STM32F3_EXTI.cs
    Execute Command    include @${CURDIR}/renode/renode_stm32f3/STM32F3_UART.cs
    Execute Command    include @${CURDIR}/renode/renode_stm32f3/STM32F3_FlashController.cs

    Execute Command    $bin = @${CURDIR}/build/stm32-pwm.elf

    Execute Command    using sysbus
    Execute Command    mach create "STM32F334R8-Nucleo"
    Execute Command    machine LoadPlatformDescription @${CURDIR}/renode/renode_stm32f3/stm32f334R8_nucleo.repl

    Execute Command          machine LoadPlatformDescriptionFromString "pt: PWMTester @ gpioPortA 5"
    Execute Command          machine LoadPlatformDescriptionFromString "gpioPortA: { 5 -> pt@0 }"

    Execute Command    sysbus LoadELF $bin

HighPercentage To Number
    [Arguments]              ${hp}
    
    ${hp}=  Remove String    ${hp}    \n
    Should Not Be True           """${hp}""" == """NaN"""  msg="No change on pin detected."
    #TODO(psv): decide if error message or set to 0
    #${hp}=  Run Keyword if   """${hp}""" == """NaN"""  Evaluate  int(0)
    ${hpn}=  Convert To Number  ${hp}
    [Return]                 ${hpn}

Should Be Equal Within Range
    [Arguments]              ${value0}  ${value1}  ${range}

    ${diff}=                 Evaluate  abs(${value0} - ${value1})

    Should Be True           ${diff} <= ${range}  msg="Duty Cycle out of range. Expected: ${value0} vs Acutal: ${value1}"