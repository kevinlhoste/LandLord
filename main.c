#include <stdio.h>

#include "common.h"
#include "FreeRTOS.h"
#include "task.h"
#include "queue.h"
#include "global.h"

#include "ROSComms.h"
#include "lcd.h"
#include "sensor.h"
#include "powermgmt.h"
#include "keypad.h"
#include "motorctrl.h"
#include "boundary.h"

#ifdef LPC177x_8x // LPC1788 DB504
TODO("Cpu lpc1788 DB504")

HeapRegion_t xHeapRegions[] = {
    { (uint8_t *) 0x10001000UL, 0xF000 }, // 60kB
    { (uint8_t *) 0x20000000UL, 0x2000 }, // 8kB
    { (uint8_t *) 0x20002000UL, 0x2000 }, // 8kB
    { (uint8_t *) 0x20004000UL, 0x4000 }, // 16kB
    { NULL, 0 }                           // Tot: 92kB
};
#else // LPC1768 DB275
TODO("Cpu lpc1768 DB275")
#error "I fucked something up in LPC175x_6x_hal, check all pin setup, chkpin, pindir etc and also the special invert functions. \
(5x/6x does not have hw invert polarity!) \
Make a complete testsuite and test all those things. LCD does work and print though so it is probably something with reading a pin state. \
Something fishy going on.. :("
HeapRegion_t xHeapRegions[] = {
    { (uint8_t *) 0x10001000UL, 0x7000 }, // 28kB
    { (uint8_t *) 0x2007C000UL, 0x4000 }, // 16kB
    { (uint8_t *) 0x20080000UL, 0x4000 }, // 16kB
    { NULL, 0 }                           // Tot: 60kB
};
#endif
/*
https://stackoverflow.com/questions/44038428/include-git-commit-hash-and-or-branch-name-in-c-c-source

arm-none-eabi-gdb main.elf
target extended-remote 10.42.43.164:3333

*/

static void task_DigitalTest(void *pvParameters) {
    for (;;) {
        GPIO_SET_PIN(LCD_BACKLIGHT);
        vTaskDelay(xDelay500);
        GPIO_CLR_PIN(LCD_BACKLIGHT);
        vTaskDelay(xDelay500);
    }
}

int main(void) {
    setbuf(stdout, NULL);
    vPortDefineHeapRegions(xHeapRegions);

    
    SystemCoreClockUpdate();
    // https://www.keil.com/pack/doc/CMSIS/Core/html/group__NVIC__gr.html
    NVIC_SetPriorityGrouping( 2 ); 
    //NVIC_SetPriority(TIMER1_IRQn, configMAX_SYSCALL_INTERRUPT_PRIORITY);

    hardware_Init();
    
    xScreenMsgQueue = xQueueCreate(6, sizeof(xScreenMsgType));
    xSensorQueue = xQueueCreate(1, sizeof(xSensorMsgType));
    xMotorMsgQueue = xQueueCreate(10, sizeof(xMotorMsgType));
    xBoundaryMsgQueue = xQueueCreate(1, sizeof(xBoundaryMsgType));
    
    //xTaskCreate(task_DigitalTest, "Digital", 128, NULL, 4, &xHandle[taskcounter++]);

//                                                    Prio
    xTaskCreate(powerMgmt_Task, "PowerMgmt", 200, NULL, 7, &xHandle[taskcounter++]);
    xTaskCreate(ROSComms_Task,  "RosComms",  512, NULL, 5, &xHandle[taskcounter++]);
    xTaskCreate(motorCtrl_Task, "MotorCtrl", 300, NULL, 5, &xHandle[taskcounter++]);
    xTaskCreate(sensor_Task,    "Sensor",    300, NULL, 4, &xHandle[taskcounter++]);
    xTaskCreate(boundary_Task,  "Boundary",  512, NULL, 3, &xHandle[taskcounter++]);
    xTaskCreate(LCD_Task,       "LCD",       378, NULL, 2, &xHandle[taskcounter++]);
    xTaskCreate(keypad_Task,    "Keypad",    150, NULL, 2, &xHandle[taskcounter++]);

    vTaskStartScheduler();
    // Should never get here.
    printf("Insufficient RAM!");
    for (;;) {
        GPIO_SET_PIN(LCD_BACKLIGHT);
        vTaskDelay(xDelay100);
        GPIO_CLR_PIN(LCD_BACKLIGHT);
        vTaskDelay(xDelay100);
        
    }
}
