#include <stm32f3xx_ll_gpio.h>
#include <stm32f3xx_ll_cortex.h>
#include <stm32f3xx_ll_rcc.h>

// STM32F334R8 green led - PA5
#define LED_PORT                GPIOA
#define LED_PIN                 LL_GPIO_PIN_5
#define LED_PORT_CLK_ENABLE()   { RCC->AHBENR |= RCC_AHBENR_GPIODEN; }

void SysTick_Handler(void)
{
    static int counter = 0;
    counter++;

    // 1 Hz blinking
    if ((counter % 500) == 0)
        LL_GPIO_TogglePin(LED_PORT, LED_PIN);
}

void initGPIO()
{
    LED_PORT_CLK_ENABLE();

    LL_GPIO_SetPinMode(LED_PORT, LED_PIN, LL_GPIO_MODE_OUTPUT);
    LL_GPIO_SetPinOutputType(LED_PORT, LED_PIN, LL_GPIO_OUTPUT_PUSHPULL);
}

int main(void)
{
    initGPIO();

    // 1kHz ticks
    SystemCoreClockUpdate();
    SysTick_Config(SystemCoreClock / 1000);

    while(1);

    return 0;
}
