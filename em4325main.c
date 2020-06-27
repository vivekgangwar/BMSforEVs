/**
 * Author(s): Rahul Meena, Vivek Gangwar
 * Created:   19.02.2020
 * 
 * (c) Copyright by DESE, IISc Bangalore.
 **/

#include "nrf_drv_spi.h"
#include "app_util_platform.h"
#include "nrf_gpio.h"
#include "nrf_delay.h"
#include "nrf_log.h"
#include "boards.h"
#include "app_error.h"
#include <string.h>

#if defined(BOARD_PCA10036) || defined(BOARD_PCA10040)
#define SPI_CS_PIN   29 /**< SPI CS Pin.*/
#elif defined(BOARD_PCA10028)
#define SPI_CS_PIN   4  /**< SPI CS Pin.*/
#else
#error "Example is not supported on that board."
#endif

#define SPI_INSTANCE  0 /**< SPI instance index. */
static const nrf_drv_spi_t spi = NRF_DRV_SPI_INSTANCE(SPI_INSTANCE);  /**< SPI instance. */
static volatile bool spi_xfer_done;  
/**< Flag used to indicate that SPI instance completed the transfer. */
static uint8_t slave_reply_length = 1;	
/* length of slave reply expected, default value is 1 for status when not specified, user should specify it while writing m_tx_buff1*/

static uint8_t master_cmd_length  = 1;	/* length of master command, user should specify it while writing m_tx_buff1*/
//#define TEST_STRING "Nordic"
static const uint8_t tx_buf_len = 4;
static const uint8_t rx_buf_len = 15;
static uint8_t       m_tx_buf1[tx_buf_len];           /**< TX buffer. */
static uint8_t       m_rx_buf1[rx_buf_len];    		  /**< RX buffer. */

/**
 * @brief SPI user event handler.
 * @param event
 */
void spi_event_handler(nrf_drv_spi_evt_t const * p_event)
{    
		spi_xfer_done = true;
		//setting spi transfer flag high to wake up from wait state
		NRF_LOG_PRINTF("\n Sent     : ");
		for(int i=0; i< p_event->data.done.tx_length;i++)
		{
			NRF_LOG_PRINTF("0x%x ",p_event->data.done.p_tx_buffer[i]);
			//displaying sent command
		}
		
		NRF_LOG_PRINTF("\n Received : ");
		
		int i=0;
		while(p_event->data.done.p_rx_buffer[i] == 0)				i++;
		//ignoring intial 0x00 values arising due to latency of slave to send reply
		//first valid reply's MSB will be 1, therefore it will be nonzero
			 
		for(int j=i; j< i+slave_reply_length;j++)
		{
			NRF_LOG_PRINTF("0x%x ",p_event->data.done.p_rx_buffer[j]);
			//Displaying Received data
		}
}


//function for initializating EM4325 as master 
void spi_master_init(void)
{
	LEDS_CONFIGURE(BSP_LED_0_MASK);	
	LEDS_OFF(BSP_LED_0_MASK);
	APP_ERROR_CHECK(NRF_LOG_INIT());
	NRF_LOG_PRINTF("\nInitializating EM4325 as SPI master\r\n");
	
	nrf_drv_spi_config_t spi_config;
	spi_config.ss_pin = SPI_CS_PIN;
	spi_config.mosi_pin = SPI0_CONFIG_MOSI_PIN;
	spi_config.sck_pin = SPI0_CONFIG_SCK_PIN;
	spi_config.miso_pin = SPI0_CONFIG_MISO_PIN;
	//setting SPI pins configuration
	spi_config.frequency = NRF_DRV_SPI_FREQ_125K;
	//setting frequency as 125Khz
	spi_config.mode = NRF_DRV_SPI_MODE_0;           
	spi_config.bit_order = NRF_DRV_SPI_BIT_ORDER_MSB_FIRST;
	//setting MSB first 

	APP_ERROR_CHECK(nrf_drv_spi_init(&spi, &spi_config, spi_event_handler));
	//checking for errors
}


// function for writing EM4325 RFID memory from start_address to end_address
void write(uint8_t start_address, uint8_t end_address )
{	
	uint8_t address = start_address;
	//initialing start address into address variable which will traverse through the address range to be written
	NRF_LOG_PRINTF("\n Writing Memory: 0x%x to 0x%x ",start_address,end_address);
	uint8_t			 write_data[]= {0x01,0x23,0x45,0x67,0x89,0xAB,0xCD,0xEF};
	// data array to be written in the memory, once the last element of array is readed, pointer is pointed to 1st element of array
	uint8_t			 write_data_index = 0;
	// points to element of data array
	while(1)
	{
		memset(m_rx_buf1, 0, rx_buf_len);	
		// Reset rx buffer
		memset(m_tx_buf1, 0, tx_buf_len);
		// Reset tx buffer 
		spi_xfer_done = false;
		//setting spi transfer flag low, going in wait for execution state

		if(address == end_address+1)
		// breaks when end_address is written
		{
			NRF_LOG_PRINTF("\n Writing Memory Completed");
			break;
		}
		m_tx_buf1[0]=0xE8;	
		//1st byte is write command
		m_tx_buf1[1]=address++;
		//2nd byte is address to be written
		m_tx_buf1[2]=write_data[write_data_index++];
		//3rd byte is most significant byte of data to be written
		m_tx_buf1[3]=write_data[write_data_index++];
		//4th byte is least significant byte of data to be written
		
		if (write_data_index == 8) write_data_index = 0;
		//resetting the pointer location to the first element of the data array
		
		master_cmd_length  = 4; 
		//4 bytes command length
		slave_reply_length = 1;	
		//1 bytes command to be received
		
		APP_ERROR_CHECK(nrf_drv_spi_transfer(&spi, m_tx_buf1, master_cmd_length, m_rx_buf1, rx_buf_len));
		//checking for any errors
				
		while (!spi_xfer_done)
		{
			__WFE();	
			//wait for execution
		}
		//waits for execution till any SPI event is received (transfer done flag is made high)
		LEDS_INVERT(BSP_LED_0_MASK);
		//Inverts LED mask
		nrf_delay_ms(200);	//200 ms delay between consecutive commands
	}
}


// function for reading EM4325 RFID memory from start_address to end_address
void read(uint8_t start_address, uint8_t end_address )
{
	uint8_t address = start_address;
	//initialing start address into address variable which will traverse through the address range to be read
	NRF_LOG_PRINTF("\n Reading Memory: 0x%x to 0x%x ",start_address,end_address);
		while(1)
	{
		memset(m_rx_buf1, 0, rx_buf_len);	
		// Reset rx buffer
		memset(m_tx_buf1, 0, tx_buf_len);
		// Reset tx buffer
		
		spi_xfer_done = false;
		//Reset transfer done flag

		if(address == end_address+1)		
		// breaks when end_address is readed
		{
			NRF_LOG_PRINTF("\n Reading Memory Completed");
			break;
		}
		
		m_tx_buf1[0]=0xE7;
		//read command for EM4325
		m_tx_buf1[1]=address++;
		//address to be read is stored in buffer and incremented
		
		master_cmd_length  = 2; 
		//2 bytes command length
		slave_reply_length = 3;	
		//3 bytes command to be received
		
		APP_ERROR_CHECK(nrf_drv_spi_transfer(&spi, m_tx_buf1, master_cmd_length, m_rx_buf1, rx_buf_len));
		//checking for any errors

		while (!spi_xfer_done)
		{
			__WFE();	
			//wait for execution
		}
		//waits for execution till any SPI event is received (transfer done flag is made high)

				
		LEDS_INVERT(BSP_LED_0_MASK);
		//Invert LED mask
		nrf_delay_ms(200);	//200 ms delay between consecutive commands
	}
}
int main(void)
{
	spi_master_init();
	//initiallising Em4325 as master
	write(0x2C, 0x3C);
	// writing EM4325 from address to 0x2c to 0x3c by pseudo data
	read(0x2C, 0x3C);
	// reading EM4325 from address to 0x2c to 0x3c

}