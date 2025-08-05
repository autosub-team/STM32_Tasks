#include <stm32f3xx_ll_gpio.h>
#include <stm32f3xx_ll_cortex.h>
#include <stm32f3xx_ll_rcc.h>

#define LED_PORT                GPIOA
#define LED_PIN                 LL_GPIO_PIN_5

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
    RCC->AHBENR |= RCC_AHBENR_GPIOAEN;

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
