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
Test for correct Implementation
    [Tags]    sels
    [Documentation]          Checks relevant Registers for correct values

    Create Nucleo Board

    Execute Command              pause
    Execute Command              emulation RunFor "5"

    ${GPIOA_Clock_Enabled}=      Execute Command    sysbus.rcc ReadDoubleWord 20
    Should Be Equal              ${{(${GPIOA_Clock_Enabled}>>17) & 1}}    1    msg = "GPIOA's clock is not enabled!"

    ${TIM2__Clock_Enabled}=      Execute Command    sysbus.rcc ReadDoubleWord 28
    Should Be Equal              ${{(${TIM_Clock_Enabled}>>0) & 1}}       1    msg = "TIM2's clock is not enabled!"

    ${GPIOA_mode}=               Execute Command    gpioPortA ReadDoubleWord 0
    Should Be Equal              ${{(${GPIOA_mode}>>10) & 0b11}}          2    msg = "GPIOA5 is not configured for Alternate Function!"
    
    ${GPIOA_AF_fun}=             Execute Command    gpioPortA ReadDoubleWord 32
    Should Be Equal              ${{(${GPIOA_AF_fun}>>20) & 0b1111}}      1    msg = "GPIOA5 is not configured with the correct Alternate Function"

    ${TIM2_Control1}=            Execute Command    sysbus.timer2 ReadDoubleWord 0 
    Should be Equal              ${{(${TIM2_Control1}>>0) & 0b10001}}     1    msg = "Either counter not enabled or direction of counter is wrong"          


Test for correct Duty Cycle
    [Tags]    sels

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
    ${tim2_PRESCALER}=  Execute Command  sysbus.timer2 ReadDoubleWord 40
    ${tim2_ARR}=  Execute Command  sysbus.timer2 ReadDoubleWord 44
    


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

    # starts simulation - be careful with servo testbench 
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