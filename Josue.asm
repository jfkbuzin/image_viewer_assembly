; Nome: Josué Filipe Keglevich de Buzin
; Cartão: 166409
	ASSUME CS: CODIGO, SS: PILHA, DS: DADOS

CR       EQU    0DH ; constante - codigo ASCII do caractere "carriage return"
LF       EQU    0AH ; constante - codigo ASCII do caractere "line feed"
BKSPC    EQU    08H ; constante - codigo ASCII do caractere "backspace"

PILHA   SEGMENT STACK
	DW 1000 DUP (0)
PILHA   ENDS

DADOS   SEGMENT
MENSAGEM  DB 'Josue Filipe Keglevich de Buzin', CR, LF
TAMANHO   EQU $-MENSAGEM
MENSAGEM2 DB 'Cartao 166409', CR, LF
TAMANHO2  EQU $-MENSAGEM2
nome      db 64 dup (?)
buffer    db 128 dup (?)
pede_nome db 'Nome do arquivo de imagem: ','$'
erro      db 'Arquivo nao existe. Digite uma Tecla.',CR,LF,'$'
msg_final db 'Fim do programa.',CR,LF,'$'
form_err  db 'Arquivo com formato errado. Digite uma Tecla.',CR,LF,'$'
tam_err   db 'Arquivo com tamanho errado. Digite uma Tecla.',CR,LF,'$'
msg_ab    db 'Arquivo Aberto. Digite uma Tecla.',CR,LF,'$'
larg	  db 'Largura:',CR,LF,'$'
alt		  db 'Altura:',CR,LF,'$'
handler   dw ?
contador  db 0 ; contador
contadorb dw 0 ;
contadorc dw 0
rot		  db 0
contador2 dw 0 
linhag    dw 0 ; Coordenada de linha em modo gráfico
colg	  dw 0 ; Coordenada de coluna em modo gráfico

string db 10 dup('$')

DADOS   ENDS

CODIGO  SEGMENT
START:  MOV AX, DADOS    ; Inicializa segmento de dados
		MOV DS, AX
		MOV ES, AX    ; idem em ES
	
		call DEF_ATRIBS ; define atributos da tela
		CALL FRASE
		
; pede nome do arquivo
de_novo: lea    dx,pede_nome ; endereco da mensagem em DX
         mov    ah,9     ; funcao exibir mensagem no AH
         int    21h      ; chamada do DOS
; le nome do arquivo
         lea    di, nome
         mov    ah,1
         int    21h	; le um caracter com eco
         cmp    al,CR   ; compara com carriage return
         je     jumpf
         cmp    al,BKSPC ; se era um "backspace"
         je     apagar   ; precisa apagar o caractere lido anterior
         mov    [di],al ; coloca no buffer
         inc    di
entrada: mov    ah,1
         int    21h	; le um caracter com eco
         cmp    al,CR   ; compara com carriage return
         je     continua
         cmp    al,BKSPC ; se era um "backspace"
         je     apagar   ; precisa apagar o caractere lido anterior
         mov    [di],al ; coloca no buffer
         inc    di
         jmp    entrada

jumpf:   jmp    fim2
		 
apagar:  cmp    di,offset nome  ; se nao havia caractere antes do "backspace"
         je     entrada          ; volta a ler caractere sem mudar DI, CX, string
         mov    dl,' '            ; escreve um espaco na posicao
         mov    ah,2              ; em que esta o cursor na tela
         int    21h     
         mov    dl,BKSPC          ; escreve "backspace" na tela, para 
         mov    ah,2              ; recuar o cursor sobre o espaco escrito
         int    21h
         dec    di                ; recua o ponteiro do string para caractere anterior
         mov    byte ptr [di],' ' ; e apaga ultimo caractere lido antes do BKSPC
         inc    cx                ; "desconta" o caractere apagado
         jmp    entrada           ; vai ler proximo caractere
		 
continua:mov    byte ptr [di],0  ; forma string ASCIIZ com o nome do arquivo
         mov    dl,LF   ; escreve LF na tela
         mov    ah,2
         int    21h
;
; abre arquivo para leitura 
abrindo: mov    ah,3dh    ;abre arquivo
         mov    al,0      ;0 = leitura, 1 = escrita, 2 = leitura e escrita
         lea    dx,nome   ;ponteiro para nome do arquivo
         int    21h
         jnc    abriu_ok
		 
		 CALL DEF_ATRIBS
		 CALL cursor
         lea    dx,erro  ; endereco da mensagem em DX
         mov    ah,9     ; funcao exibir mensagem no AH
         int    21h      ; chamada do DOS
		 
		 call espera_tecla
		 CALL limpa_tela
		 CALL DEF_ATRIBS
		 CALL cursor
         jmp    de_novo
;
abriu_ok:mov handler,ax

;cabeçalho arq:
;ID 2 bytes
ID:		 mov ah,3fh      ; le um caracter do arquivo, se cf=0, sucesso e Ax contem o numero de bytes lidos
         mov bx,handler
         mov cx,1        ;numero de bytes a ler
         lea dx,buffer
         int 21h
		 mov al, 'C'
         cmp al, buffer
         je ID2
		 jmp erroab
		   
ID2:	 mov ah,3fh      
         mov bx,handler
         mov cx,1        
         lea dx,buffer
         int 21h
		 mov al, 'W'
         cmp al, buffer
         je FTYP
		 jmp erroab

erroab:  CALL DEF_ATRIBS
		 CALL cursor
		 lea    dx,form_err ; endereco da mensagem em DX
         mov    ah,9     ; funcao exibir mensagem no AH
         int    21h      ; chamada do DOS
		 
		 call espera_tecla
		 CALL limpa_tela
		 CALL DEF_ATRIBS
		 CALL cursor
         jmp    de_novo
		 
errot:   CALL DEF_ATRIBS
		 CALL cursor
		 lea    dx,tam_err ; endereco da mensagem em DX
         mov    ah,9     ; funcao exibir mensagem no AH
         int    21h      ; chamada do DOS

		 call espera_tecla
		 CALL limpa_tela
		 CALL DEF_ATRIBS
		 CALL cursor
         jmp    de_novo 
		 
;FTYP 2 bytes
FTYP:	 mov ah,3fh      ; le um caracter do arquivo, se cf=0, sucesso e Ax contem o numero de bytes lidos
         mov bx,handler
         mov cx,1        ;numero de bytes a ler
         lea dx,buffer
         int 21h
		 
		 mov al, 1
         cmp al, buffer
         jne erroab
		 
		 mov ah,3fh      ; le um caracter do arquivo, se cf=0, sucesso e Ax contem o numero de bytes lidos
         mov bx,handler
         mov cx,1        ;numero de bytes a ler
         lea dx,buffer
         int 21h

		 mov al, 0
		 cmp al, buffer ;compara para saber se o byte é zero
		 jne erra

;HCSIZE 2 bytes
HCSIZE:  mov ah,3fh      ; le um caracter do arquivo, se cf=0, sucesso e Ax contem o numero de bytes lidos
         mov bx,handler
         mov cx,1        ;numero de bytes a ler
         lea dx,buffer
         int 21h

		 mov al, 6
         cmp al, buffer ;compara para saber se o byte é seis
         jne erra
		 
		 mov ah,3fh      ; le um caracter do arquivo, se cf=0, sucesso e Ax contem o numero de bytes lidos
         mov bx,handler
         mov cx,1        ;numero de bytes a ler
         lea dx,buffer
         int 21h

		 mov al, 0
		 cmp al, buffer ;compara para saber se o byte é zero
		 je CID
		 
erra:	 jmp erroab
		

;cabeçalho controle:
;CID 1 byte
CID:	 mov ah,3fh      ; le um caracter do arquivo, se cf=0, sucesso e Ax contem o numero de bytes lidos
         mov bx,handler
         mov cx,1        ;numero de bytes a ler
         lea dx,buffer
         int 21h
	
		 mov al, 00H
         cmp al, buffer
         je BPP
		 jmp erroab
		
;BPP 1 byte
BPP:	 mov ah,3fh      ; le um caracter do arquivo, se cf=0, sucesso e Ax contem o numero de bytes lidos
         mov bx,handler
         mov cx,1        ;numero de bytes a ler
         lea dx,buffer
         int 21h
		
		 mov al, 01H
         cmp al, buffer
         je SWIDTH
		 jmp erroab
	
;WIDTH 2 bytes
SWIDTH:  mov ah,3fh      ; le um caracter do arquivo, se cf=0, sucesso e Ax contem o numero de bytes lidos
         mov bx,handler
         mov cx,1        ;numero de bytes a ler
         lea dx,buffer
         int 21h
		 mov ax, word ptr buffer

		 mov contadorb, ax

		 mov ah,3fh      ; le um caracter do arquivo, se cf=0, sucesso e Ax contem o numero de bytes lidos
         mov bx,handler
         mov cx,1        ;numero de bytes a ler
         lea dx,buffer
         int 21h
		 mov ax, word ptr buffer
		 
		 cmp ax, 1
		 je soma
		 jb SHEIGHT
		 jmp errot
		 
soma:	 add contadorb, 256
		 cmp contadorb, 431
		 jb SHEIGHT
		 jmp errot
		

;HEIGHT 2 bytes
SHEIGHT: mov ah,3fh      ; le um caracter do arquivo, se cf=0, sucesso e Ax contem o numero de bytes lidos
         mov bx,handler
         mov cx,1        ;numero de bytes a ler
         lea dx,buffer
         int 21h
		 mov ax, word ptr buffer
		
		 mov contadorc, ax

		 mov ah,3fh      ; le um caracter do arquivo, se cf=0, sucesso e Ax contem o numero de bytes lidos
         mov bx,handler
         mov cx,1        ;numero de bytes a ler
         lea dx,buffer
         int 21h
		 mov ax, word ptr buffer
		 
		 cmp ax, 1
		 je soma2
		 jb pstart
		 jmp errot
		 
soma2:	 add contadorc, 256
		 cmp contadorc, 401
		 jb pstart
		 jmp errot
		 
;desenhar pixels
pstart:	 CALL DEF_ATRIBS
		 CALL cursor
		 
		 lea    dx,larg ; endereco da mensagem em DX
         mov    ah,9     ; funcao exibir mensagem no AH
         int    21h      ; chamada do DOS
		 
		 mov ax,contadorb
		 mov bx ,10
		 mov cx,0

l1:		 mov dx,0
		 div bx
		 add dx,48
		 push dx
		 inc cx
		 cmp ax,0
		 jne l1
		 mov bx ,offset string 

l2:		 pop dx           
		 mov [bx],dx
		 inc bx
		 loop l2
		 mov ah,09
		 mov dx,offset string
		 int 21h
		 
		 call espera_tecla
		 
		 CALL DEF_ATRIBS
		 CALL cursor

		 lea    dx,alt   ; endereco da mensagem em DX
         mov    ah,9     ; funcao exibir mensagem no AH
         int    21h      ; chamada do DOS		
		 
		 mov ax,contadorc
		 mov bx ,10
		 mov cx,0

la1:	 mov dx,0
		 div bx
		 add dx,48
		 push dx
		 inc cx
		 cmp ax,0
		 jne la1
		 mov bx ,offset string 

la2:	 pop dx           
		 mov [bx],dx
		 inc bx
		 loop la2
		 mov ah,09
		 mov dx,offset string
		 int 21h			 
		 
		 call espera_tecla
		 
		 CALL DEF_ATRIBS
		 mov     linhag, 0
		 mov     colg  , 0
looph:   mov     contador2, 8
		 mov 	 ah,3fh      ; le um caracter do arquivo, se cf=0, sucesso e Ax contem o numero de bytes lidos
         mov 	 bx,handler
         mov 	 cx,1        ;numero de bytes a ler
         lea 	 dx,buffer
         int 	 21h 
		 mov     cl, buffer
		 mov     rot, cl
separa1: rol     rot, 1
		 jc      um
		 mov     al, 0
		 mov     bh, 0
         mov     cx, colg
         mov     dx, linhag
         mov     ah, 0ch
         int     10h
		 jmp     zero
		 
um:      mov     al, 1		; 0 é preto, 1 a 15 é branco (16 "cores" no total)
         mov     bh, 0
         mov     cx, colg
         mov     dx, linhag
         mov     ah, 0ch
         int     10h

zero:    inc     colg
		 mov 	 ax, contadorb
		 cmp     colg, ax;320
		 jb      oito1
		 jmp     loopv
	
oito1:   dec     contador2
         jnz     separa1 
		 jmp     looph
		 
loopv:   mov     colg, 0
         inc     linhag
		 mov 	 ax, contadorc	
		 cmp     linhag, ax;160
		 jb      looph
		 jmp     fim
		 
;
fim:     CALL cursor
		 lea    dx,msg_ab ; endereco da mensagem em DX
         mov    ah,9     ; funcao exibir mensagem no AH
         int    21h      ; chamada do DOS
 
		 call espera_tecla
		 mov ah,3eh	 ; fecha arquivo
         mov bx,handler
         int 21h
		 
		 CALL limpa_tela
		 CALL DEF_ATRIBS
		 
		 
		 CALL cursor
		 jmp de_novo
; 	     mov ah,3ch - cria arquivo
;  	     lea dx,nome do arquivo novo
;    	  mov ah,40h - escreve no arquivo
;     	  mov bx,handler
;		 mov cx,1        ;numero de bytes a escrever
;        lea dx,buffer   ;se cf=0, sucesso e AX contem numero de bytes escritos
fim2:    mov    al,7		; numero de linhas (zero = toda a janela)
         mov    ah,0          ; scroll window up
         int    10h   	

		 lea    dx,msg_final ; endereco da mensagem em DX
         mov    ah,9     ; funcao exibir mensagem no AH
         int    21h      ; chamada do DOS
        
         mov    ax,4c00h ; funcao retornar ao DOS no AH
         int    21h      ; chamada do DOS
	
DEF_ATRIBS PROC
         mov    al,11h		; numero de linhas (zero = toda a janela)
         mov    ah,0          ; scroll window up
         int    10h        
         ret
DEF_ATRIBS ENDP

FRASE   PROC NEAR
		 mov bh,0
		 mov dl,0         ; x	
		 mov dh,25		; y
		 mov ah,2         ; scroll window up
		 int 10h  
		 MOV BX, 0001H
		 LEA DX, MENSAGEM
		 MOV CX, TAMANHO
		 MOV AH, 40H
		 INT 21H
		 LEA DX, MENSAGEM2
		 MOV CX, TAMANHO2
		 MOV AH, 40H
		 INT 21H     ; Escreve mensagem
		 RET
FRASE   ENDP


LER PROC NEAR
		 mov ah,3fh      ; le um caracter do arquivo, se cf=0, sucesso e Ax contem o numero de bytes lidos
		 mov bx,handler
		 mov cx,1        ;numero de bytes a ler
		 lea dx,buffer
		 int 21h
		 RET
LER ENDP

espera_tecla proc
         mov    ah,0               ; funcao esperar tecla no AH
         int    16h                ; chamada do DOS
         ret
espera_tecla endp

limpa_tela proc
; limpa toda a tela (parte definida para gráfico) e vai para 0,0
         mov     dh,24		; linha 24
         mov     dl,79      ; coluna 79
         mov     ch,0		; linha zero  
         mov     cl,0		; coluna zero
         mov     bh,00h     ; atributo de preenchimento (fundo preto)
         mov     al,0		; numero de linhas (zero = toda a janela)
         mov     ah,6         ; scroll window up
         int     10h          ; chamada BIOS (video)  
         ret
limpa_tela endp

cursor proc
		 mov bh,0
		 mov dl,0         ; x	
		 mov dh,25		; y
		 mov ah,2         ; scroll window up
		 int 10h
		 ret
cursor endp

CODIGO  ENDS
	END START
