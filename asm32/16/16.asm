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
szBuffer	db	256 dup (0)
		.const
szTitle		db 	'��ӡ',0
dwSize		dd	4096
szAllocResFmt	db	'���������ڴ��ַ:%d',0
szAllocComFmt	db	'�ύ�����ڴ��ַ:%d',0
;-------------------
; code
;-------------------
.code
_MainProc proc
	LOCAL	lpAddress
	pushad	
	;���������ַ
	invoke	VirtualAlloc,NULL,dwSize,MEM_RESERVE,PAGE_NOACCESS
	mov	lpAddress,eax
	invoke	wsprintf,addr szBuffer,addr szAllocResFmt,lpAddress
	invoke	MessageBox,NULL,addr szBuffer,addr szTitle,MB_OK
	
	;�ύ���������ַ
	invoke	VirtualAlloc,lpAddress,4096,MEM_COMMIT,PAGE_READWRITE
	mov	lpAddress,eax
	invoke	wsprintf,addr szBuffer,addr szAllocComFmt,lpAddress
	invoke	MessageBox,NULL,addr szBuffer,addr szTitle,MB_OK	
	
	;�����ύ�������ַ�������������ڴ����ļ��У���������30��
	invoke	VirtualLock,lpAddress,4096
	invoke  VirtualUnlock,lpAddress,4096
	
	;�޸������ַ����
	invoke	VirtualProtect,lpAddress,4096,PAGE_READONLY,NULL
	
	;���ύ�����ַ
	invoke	VirtualFree,lpAddress,0,MEM_DECOMMIT
	
	;�ͷ������ַ
	invoke	VirtualFree,lpAddress,0,MEM_RELEASE
	popad
	ret
_MainProc endp

start:
	invoke	GetModuleHandle,NULL
	mov	hInstance,eax	
	invoke	_MainProc
	invoke	ExitProcess,NULL
end start	