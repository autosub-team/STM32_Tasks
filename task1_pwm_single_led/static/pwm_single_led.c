/* STM32-Task 1: Single LED PWM

In this task, your goal is to utilize the PWM mode in a Timer, which is connected
to one of the LEDs on our Extension Board.

Put relevant code for setting up the peripherals in their respective functions and
put code to start relevant peripherals at the respective position in the code below

Good Luck!

*/

#include "stm32f3xx_ll_rcc.h"
#include "stm32f3xx_ll_bus.h"
#include "stm32f3xx_ll_system.h"
#include "stm32f3xx_ll_utils.h"
#include "stm32f3xx_ll_tim.h"
#include "stm32f3xx_ll_gpio.h"
#include <stdint.h>

void SystemClock_Config(void);
static void GPIO_Init(void);
static void TIM_Init(void);


int main(void)
{
  SystemClock_Config(); // Configure the system clock

  GPIO_Init(); // Initializes GPIO
  TIM_Init(); // Initializes Timer

  /* put further relevant code for starting peripherals here*/


  /* Infinite loop */
  while (1)
  {
  }
}


/** TIM Initialization Function
 * put here all code relevant to the timer configuration
*/
static void TIM_Init(void)
{

}


/** GPIO Initialization Function
 * put here all code relevant to the gpio configuration
  */
static void GPIO_Init(void)
{
  
}







/* System Clock Configuration, do not change code here, CPU frequency is 64 MHz */
void SystemClock_Config(void)
{
  LL_FLASH_SetLatency(LL_FLASH_LATENCY_2);
  while(LL_FLASH_GetLatency()!= LL_FLASH_LATENCY_2);
  LL_RCC_HSI_Enable();

   /* Wait till HSI is ready */
  while(LL_RCC_HSI_IsReady() != 1);
  LL_RCC_HSI_SetCalibTrimming(16);
  LL_RCC_PLL_ConfigDomain_SYS(LL_RCC_PLLSOURCE_HSI_DIV_2, LL_RCC_PLL_MUL_16);
  LL_RCC_PLL_Enable();

   /* Wait till PLL is ready */
  while(LL_RCC_PLL_IsReady() != 1);
  LL_RCC_SetAHBPrescaler(LL_RCC_SYSCLK_DIV_1);
  LL_RCC_SetAPB1Prescaler(LL_RCC_APB1_DIV_2);
  LL_RCC_SetAPB2Prescaler(LL_RCC_APB2_DIV_1);
  LL_RCC_SetSysClkSource(LL_RCC_SYS_CLKSOURCE_PLL);

   /* Wait till System clock is ready */
  while(LL_RCC_GetSysClkSource() != LL_RCC_SYS_CLKSOURCE_STATUS_PLL);

  LL_Init1msTick(64000000);
  LL_SetSystemCoreClock(64000000);
}

