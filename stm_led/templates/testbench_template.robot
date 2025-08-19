*** Settings ***
Resource            ${RENODEKEYWORDS}

Suite Setup         Setup
Suite Teardown      Teardown
Test Teardown       Test Teardown


*** Variables ***
${desired_period_clks}          {{PERIODCLKS}}
${desired_duty_cycle_clks}      {{DUTYCLKS}}
${simulation_cycles}            {{SIMCYCLES}}
${percentage_tolerance}         1


*** Test Cases ***
Test for correct Duty Cycle
    [Tags]    sels
    Create Nucleo Board

    Execute Command          gpioPortA.pt Reset
    Execute Command          pause
    Execute Command          emulation RunFor "5"

    ${hp}=  Execute Command  gpioPortA.pt HighPercentage
    ${actual_percent}=    Percentage To Number  ${hp}
    ${expected_percent}=  Evaluate  ${desired_duty_cycle_clks} / ${desired_period_clks} * 100
    Should Be Equal Within Range  ${expected_percent}  ${actual_percent}  ${percentage_tolerance}  "Duty Cycle out of range. Expected: ${expected_percent} vs Acutal: ${actual_percent}"

    ${ht}=  Execute Command  gpioPortA.pt HighTicks
    ${hs}=  Ticks To Seconds  ${ht}

    ${tim2_enabled}=  Execute Command  sysbus.timer2 Enabled
    ${tim2_divider}=  Execute Command  sysbus.timer2 Divider
    ${tim2_limit}=  Execute Command  sysbus.timer2 Limit
    ${tim2_mode}=  Execute Command  gpioPortA ReadDoubleWord 0


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
    # This line is needed to connect the CC channel to the correct pin.
    Execute Command          machine LoadPlatformDescriptionFromString "timer2: { 0 -> gpioPortA@5 }"

    Execute Command    sysbus LoadELF $bin

Percentage To Number
    [Arguments]              ${hp}
    
    ${hp}=  Remove String    ${hp}    \n
    Should Not Be True           """${hp}""" == """NaN"""  msg="No change on pin detected."
    #TODO(psv): decide if error message or set to 0
    #${hp}=  Run Keyword if   """${hp}""" == """NaN"""  Evaluate  int(0)
    ${hpn}=  Convert To Number  ${hp}
    [Return]                 ${hpn}

Ticks To Seconds
    [Arguments]              ${ht}
    
    ${ht}=  Remove String    ${ht}    \n
    #${ht}=  Run Keyword if   """${ht}""" == """NaN"""  Evaluate  int(0)
    ${ht}=  Evaluate  int(${ht}) / (10**9)
    [Return]                 ${ht}

Should Be Equal Within Range
    [Arguments]              ${value0}  ${value1}  ${range}  ${msg}

    ${diff}=                 Evaluate  abs(${value0} - ${value1})

    Should Be True           ${diff} <= ${range}  msg=${msg}