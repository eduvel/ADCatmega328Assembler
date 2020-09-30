;
; pruebaADC.asm
;


		.ORG	0X0000
		JMP		INICIO
		.ORG	0X001A
		JMP		ISR_TOV1
		.ORG	0X002A
		JMP		ISR_ADC
		.INCLUDE "division.inc"
INICIO:
		LDI		R16,HIGH(RAMEND)
		OUT		SPH,R16
		LDI		R16,LOW(RAMEND)
		OUT		SPL,R16
		LDI		R16,(1<<DDB5) 
		OUT		DDRB,R16

		CALL	INIT_UART
		CALL	INIT_TIMER

		;CONFIGURACION ADC
		LDI		R16,(1<<REFS0)
		STS		ADMUX,R16
		;LDI		R16,(1<<ADEN)|(1<<ADATE)|(1<<ADIE)|(1<<ADPS2)|(1<<ADPS1)
		LDI		R16,(1<<ADEN)|(1<<ADSC)|(1<<ADPS2)|(1<<ADPS1)
		STS		ADCSRA,R16
		LDI		R16,0
		;LDI	R16,(1<<ADTS2)|(1<<ADTS1)
		STS		ADCSRB,R16
		LDI		R16,(1<<ADC0D)
		STS		DIDR0,R16
		;FIN CONFIGURACION ADC
		SEI
VOLVER:	
		RJMP	VOLVER
ISR_ADC:
		PUSH	R17
		IN		R17,SREG
		PUSH	R17
		;LDS		R24,ADCL
		;LDS		R25,ADCH
		;CALL	DESARMAR_ENVIAR
		POP		R17
		OUT		SREG,R17
		POP		R17
		RETI

ISR_TOV1:
		PUSH	R17
		IN		R17,SREG
		PUSH	R17
		;ADC MODO POLLING
		LDS		R17,ADCSRA
		SBR		R17,(1<<ADSC)
		STS		ADCSRA,R17
ESPERAR_ADC:
		LDS		R17,ADCSRA
		SBRC	R17,ADSC
		RJMP	ESPERAR_ADC
		LDS		R24,ADCL
		LDS		R25,ADCH
		CALL	DESARMAR_ENVIAR
		;FIN LECTURA ADC

		SBI		PINB,PINB5
		LDI		R16,HIGH(3036)
		STS		TCNT1H,R16
		LDI		R16,LOW(3036)
		STS		TCNT1L,R16

		POP		R17
		OUT		SREG,R17
		POP		R17
		RETI

INIT_UART:
		LDI		R16,0				;VELOCIDAD , PARIDAD, BIT STOP, CANTIDAD DE DATOS
		STS		UCSR0A,R16			;9600,8,N,1
		LDI		R16,(1<<TXEN0)
		STS		UCSR0B, R16
		LDI		R16,(1<<UCSZ01)|(1<<UCSZ00)
		STS		UCSR0C,R16
		LDI		R16,103
		STS		UBRR0L,R16
		LDI		R16,0
		STS		UBRR0H,R16
		RET

INIT_TIMER:
		;Inicio configuraci�n timer 1
		LDI		R16,0
		STS		TCCR1A,R16
		LDI		R16,(1<<CS12)
		STS		TCCR1B,R16
		LDI		R16,0
		STS		TCCR1C,R16
		LDI		R16,(1<<TOIE1)
		STS		TIMSK1,R16
		LDI		R16,HIGH(3036)
		STS		TCNT1H,R16
		LDI		R16,LOW(3036)
		STS		TCNT1L,R16
		;Fin configuraci�n timer 1
		RET

DESARMAR_ENVIAR:
		;LDI		R25,HIGH(2345)
		;LDI		R24,LOW(2345)
		LDI		R23,HIGH(1000)
		LDI		R22,LOW(1000)
		CALL	DIVISION16
		MOV		R20,R24
		CALL	ENVIO_UART
		MOVW	R24,R26
		LDI		R23,HIGH(100)
		LDI		R22,LOW(100)
		CALL	DIVISION16
		MOV		R20,R24
		CALL	ENVIO_UART
		MOVW	R24,R26
		LDI		R23,0
		LDI		R22,10
		CALL	DIVISION16
		MOV		R20,R24
		CALL	ENVIO_UART
		MOV		R20,R26
		CALL	ENVIO_UART
		LDI		R20,10
		CALL	ESPERAR_TX
		LDI		R20,13
		CALL	ESPERAR_TX
		RET

ENVIO_UART:
		LDI		R16,48
		ADD		R20,R16
ESPERAR_TX:
		LDS		R16,UCSR0A
		SBRS	R16,UDRE0
		RJMP	ESPERAR_TX
		STS		UDR0,R20

		RET
