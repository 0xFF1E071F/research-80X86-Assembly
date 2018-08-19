.386
.model flat,stdcall
option casemap:none
;-------------------
; define
;-------------------
include rcdef.inc
;-------------------
; include
;-------------------
include windows.inc
include gdi32.inc
include user32.inc
include kernel32.inc
includelib gdi32.lib
includelib user32.lib
includelib kernel32.lib
;-------------------
; data
;-------------------
		.data?
hInstance	dd	?
lpMemory	dd 	?
lpLock0		dd	?
lpLock1		dd	?
dwLockNum	dd	?
hMemory		dd      ?
szBuffer	db  256 dup (?)

		.const
szTitle		db '��ӡ',0		
szFormat	db 'XXXXXXXXXXXXX mem add is ���:%d ��ַ0:%d,��ַ1:%d',0dh,0ah
szLockNum	db '��������:%d',0
szHandlerFormat db '���:%d',0
szMemSize	db '�ڴ�:%d',0
;-------------------
; code
;-------------------
.code
start:
	invoke GlobalAlloc,GMEM_MOVEABLE or GMEM_ZEROINIT,256
	mov    hMemory,eax
	invoke GlobalLock,hMemory
	mov    lpLock0,eax
	invoke GlobalLock,hMemory
	mov    lpLock1,eax
	invoke GlobalFlags,hMemory
	and    eax,GMEM_LOCKCOUNT
	mov    dwLockNum,eax
	.if lpLock1
		invoke wsprintf,lpLock1,addr szFormat,hMemory,lpLock0,lpLock1,dwLockNum
		invoke MessageBox,NULL,lpLock1,addr szTitle,MB_OK
	.endif 
	
	invoke GlobalHandle,lpLock1
	invoke wsprintf,addr szBuffer,addr szHandlerFormat,eax
	invoke MessageBox,NULL,addr szBuffer,addr szTitle,MB_OK
	
	invoke GlobalSize,hMemory
	invoke wsprintf,addr szBuffer,addr szMemSize,eax
	invoke MessageBox,NULL,addr szBuffer,addr szTitle,MB_OK
	
	invoke GlobalUnlock,hMemory
	invoke GlobalFlags,hMemory
	and    eax,GMEM_LOCKCOUNT
	invoke wsprintf,addr szBuffer,addr szLockNum,eax
	invoke MessageBox,NULL,addr szBuffer,addr szTitle,MB_OK
	invoke GlobalUnlock,hMemory
	
	mov    lpLock0,0
	mov    lpLock1,0
	
	invoke GlobalFree,lpMemory
	mov    lpMemory,0
	invoke ExitProcess,NULL
end start	