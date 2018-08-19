.386
.model flat,stdcall
option casemap:none
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
; Include �ļ�����
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
include		windows.inc
include		user32.inc
includelib	user32.lib
include		kernel32.inc
includelib	kernel32.lib
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
; Equ ��ֵ����
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
ICO_MAIN	equ	1000
DLG_MAIN	equ	1000
IDC_COUNTER	equ	1001
IDC_PAUSE	equ	1002
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
; ���ݶ�
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
		.data?
hInstance	dd	?
hWinMain	dd	?
hWinCount	dd	?
hWinPause	dd	?
hThread		dd	?
hEvent		dd	?

dwOption	dd	?
dwExitCode	dd	?
F_PAUSE		equ	0001h
F_COUNTING	equ	0004h

		.const
szStop		db	'ֹͣ����',0
szStart		db	'����',0
szCount		db	'%d',0
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
		.code
_Counter proc
	;LOCAL	@count
	
	;mov	@count,0 ;����0�ǲ��е�
	;invoke	wsprintf,addr @buf,addr szCount,@count
	;invoke	MessageBox,NULL,addr @buf,NULL,MB_OK
	
	pushad
	;xor	edx,edx ��Ҫ��edx���ᱻ���õĺ����޸� 
	xor	ebx,ebx
	.while	dwOption&F_COUNTING
		;.if !(dwOption&F_PAUSE)
			invoke WaitForSingleObject,hEvent,INFINITE
			inc ebx
			invoke	SetDlgItemInt,hWinMain,IDC_COUNTER,ebx,FALSE
		;.endif
	.endw
	
	popad
	mov eax,0ffffh
	ret
_Counter endp		

_ProcDlgMain proc hWnd,uMsg,wParam,lParam
	LOCAL 	@buf[128]:byte
	
	mov	eax,uMsg
	.if eax==WM_COMMAND
		mov	eax,wParam
		.if	ax==IDOK
			.if dwOption&F_COUNTING
				and dwOption,not F_COUNTING
				invoke	SetWindowText,hWinCount,addr szStart
				invoke	EnableWindow,hWinPause,FALSE
				
				;ExitThread ֻ����ֹ��ǰ�߳�
				invoke	TerminateThread,hThread,0eeeeh;�첽ִ�У����ò���������ֹ
				;invoke	wsprintf,addr @buf,addr szCount,eax
				;invoke	MessageBox,hWnd,addr @buf,NULL,MB_OK
				invoke	WaitForSingleObject,hThread,INFINITE						
				invoke	GetExitCodeThread,hThread,addr dwExitCode
				;.if dwExitCode == STILL_ACTIVE
					invoke	wsprintf,addr @buf,addr szCount,dwExitCode
					invoke	MessageBox,hWnd,addr @buf,NULL,MB_OK				
				;.endif
				invoke	CloseHandle,hThread
				mov	hThread,0
			.else
				or dwOption,F_COUNTING
				and dwOption,not F_PAUSE
				invoke	SetEvent,hEvent
				invoke	SetWindowText,hWinCount,addr szStop
				invoke	EnableWindow,hWinPause,TRUE
				invoke	CreateThread,0,0,offset _Counter,0,CREATE_SUSPENDED,0
				mov	hThread,eax
				invoke	ResumeThread,hThread
				
				;invoke	CloseHandle,eax
			.endif
		.elseif ax==IDC_PAUSE
			.if dwOption&F_PAUSE
				and dwOption,not F_PAUSE
				invoke	SetEvent,hEvent
				;invoke	ResumeThread,hThread
			.else
				or dwOption,F_PAUSE
				invoke	ResetEvent,hEvent
				;invoke	SuspendThread,hThread
			.endif
		.endif
	.elseif eax==WM_CLOSE
		invoke	EndDialog,hWnd,NULL
	.elseif eax==WM_INITDIALOG
		push	hWnd
		pop	hWinMain
		invoke	GetDlgItem,hWnd,IDOK
		mov	hWinCount,eax
		invoke	GetDlgItem,hWnd,IDC_PAUSE
		mov	hWinPause,eax
		invoke	CreateEvent,0,TRUE,TRUE,0
		mov	hEvent,eax
	.else
		mov	eax,FALSE
		ret
	.endif
	mov	eax,TRUE
	ret
_ProcDlgMain endp		
start:
	invoke	GetModuleHandle,NULL
	mov	hInstance,eax
	invoke	DialogBoxParam,eax,DLG_MAIN,NULL,offset _ProcDlgMain,0
	invoke	CloseHandle,hEvent
	invoke	ExitProcess,NULL
end start