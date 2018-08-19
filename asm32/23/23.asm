.386
.model flat,stdcall
option casemap:none
;Ԥ����
ICO_MAIN	equ	1000
DLG_MAIN	equ	1000
IDC_COUNTER1	equ	1001
IDC_COUNTER2	equ	1002
;ͷ�ļ�
include		windows.inc   	;��������
include		kernel32.inc  	;GetModuleHandle ExitProcess �Ķ���
includelib	kernel32.lib	
include		user32.inc	;EndDialog DialogBoxParam �Ķ���
includelib	user32.lib
;����
.data?
hInstance	dd			?
hWinMain	dd			?
dwThread	dd			?
dwCounter0	dd			?
dwCounter1	dd			?
hEvent		dd			?
stCritical	CRITICAL_SECTION       <?>
hMutex		dd			?
hSemaphore	dd			?
.const
nCounter	dd	10
F_THREADING	equ	0001h
szStop		db	'ֹͣ����',0
szStart		db	'����',0
;����
.code
_Counter proc uses ebx edi esi,lParam

;	ʹ���¼������ŵ����ڿ���ָ�����ƣ����Կ���̣���ȱ��Ҳ����Ϊ���Կ���̣�ռ�õ���Դ�Ƚ϶�
;	���ԱȽϺ�ʱ
;	.while  dwThread&F_THREADING
;		;���ֵ��߳������ʹ��ͬ���ķ�����Ҳ����ֲ�ͬ�������������Ϊ��ʾ��Ŀ��������Ŀ��ͬ��
;		;ֻ����ʾ��ʱ���޸ģ��޸ĵ�ʱ����ʾ�����п�����ʾ����������Ŀ
;		invoke	WaitForSingleObject,hEvent,INFINITE ;�Զ���λ��Ҳ���ǰ������һ�д��� invoke ResetEvent,hEvent
;		inc	dwCounter0
;		mov	eax,dwCounter1
;		inc	eax
;		mov	dwCounter1,eax
;		invoke	SetEvent,hEvent
;	.endw
	
;	ʹ���ٽ���	
;	.while  dwThread&F_THREADING	
;		invoke	EnterCriticalSection,addr stCritical
;		inc	dwCounter0
;		mov	eax,dwCounter1
;		inc	eax
;		mov	dwCounter1,eax
;		invoke	LeaveCriticalSection,addr stCritical
;	.endw
	
;	ʹ�û�����
;	.while	dwThread&F_THREADING	
;		invoke	WaitForSingleObject,hMutex,INFINITE
;		inc	dwCounter0
;		mov	eax,dwCounter1
;		inc	eax
;		mov	dwCounter1,eax
;		invoke	ReleaseMutex,hMutex	
;	.endw

;	ʹ���źŵ�	
	.while	dwThread&F_THREADING
		invoke	WaitForSingleObject,hSemaphore,INFINITE;ÿ��ȡһջ�ƣ������һջ
		inc	dwCounter0
		mov	eax,dwCounter1
		inc	eax
		mov	dwCounter1,eax		
		invoke	ReleaseSemaphore,hSemaphore,1,0;���µ���һջ
	.endw
	
	ret
_Counter endp
_DialogProc proc hWnd,uMsg,wParam,lParam
	mov	eax,uMsg
	.if	eax==WM_TIMER

;		ʹ���¼�����	
;		invoke	WaitForSingleObject,hEvent,INFINITE
;		invoke	SetDlgItemInt,hWnd,IDC_COUNTER1,dwCounter0,FALSE
;		invoke	SetDlgItemInt,hWnd,IDC_COUNTER2,dwCounter1,FALSE
;		invoke	SetEvent,hEvent

;		ʹ���ٽ���
;		invoke	EnterCriticalSection,addr stCritical
;		invoke	SetDlgItemInt,hWnd,IDC_COUNTER1,dwCounter0,FALSE
;		invoke	SetDlgItemInt,hWnd,IDC_COUNTER2,dwCounter1,FALSE
;		invoke	LeaveCriticalSection,addr stCritical	

;		ʹ�û�����
;		invoke	WaitForSingleObject,hMutex,INFINITE
;		invoke	SetDlgItemInt,hWnd,IDC_COUNTER1,dwCounter0,FALSE
;		invoke	SetDlgItemInt,hWnd,IDC_COUNTER2,dwCounter1,FALSE
;		invoke	ReleaseMutex,hMutex			

;		�źŵ�		
		invoke	WaitForSingleObject,hSemaphore,INFINITE;ÿ��ȡһջ�ƣ������һջ
		invoke	SetDlgItemInt,hWnd,IDC_COUNTER1,dwCounter0,FALSE
		invoke	SetDlgItemInt,hWnd,IDC_COUNTER2,dwCounter1,FALSE	
		invoke	ReleaseSemaphore,hSemaphore,1,0;���µ���һջ		
		
	.elseif	eax==WM_COMMAND
		mov	eax,wParam
		.if	ax==IDOK		
			.if dwThread&F_THREADING
				and	dwThread,not F_THREADING
				invoke	SetDlgItemText,hWnd,IDOK,addr szStart
				invoke	KillTimer,hWnd,1
				invoke	CloseHandle,hEvent
				invoke	CloseHandle,hMutex
				invoke	CloseHandle,hSemaphore
				invoke	DeleteCriticalSection,addr stCritical
			.else
				mov	dwCounter0,0
				mov	dwCounter1,0
				invoke	SetDlgItemText,hWnd,IDOK,addr szStop
				or	dwThread,F_THREADING
				xor 	ebx,ebx
				.while ebx<nCounter
					inc	ebx
					invoke	CreateThread,0,0,offset _Counter,0,0,0
					invoke	CloseHandle,eax
				.endw
				invoke	SetTimer,hWnd,1,500,0
				;�¼�������λ��True����λ��False������λ����˼�ǿ���True
				;��������������False,ռ����True,�����¼������Ǹպ��෴�ģ�
				;���԰��¼���������ɿ��أ����ش�Ϊtrue����ʱ����ͨ������������
				;��������Ϊtrue��ʾ���ڻ��⣬���Բ���ͨ����false��ʾû�л���
;				invoke	OpenEvent,eventName
;				invoke	OpenMutex,muTexName
;				invoke	OpenSemaphore,semaphoreName
;				�¼�
				invoke	CreateEvent,0,FALSE,TRUE,0
				mov	hEvent,eax
;				�ٽ���				
				invoke	InitializeCriticalSection,addr stCritical
;				������				
				invoke	CreateMutex,0,FALSE,0
				mov	hMutex,eax
;				�źŵ�  ��ʼֵ��ʾ��ʱ���ж���ջ�������ģ�����һ�������Ǳ�ʾһ���ж���ջ��
				invoke	CreateSemaphore,0,1,1,0	
				mov	hSemaphore,eax			
			.endif
		.endif
	.elseif	eax==WM_CLOSE
		invoke	EndDialog,hWnd,0
	.elseif	eax==WM_INITDIALOG
		push	hWnd
		pop	hWinMain
	.else	
		mov	eax,FALSE
		ret
	.endif
	mov	eax,TRUE
	ret
_DialogProc endp

start:
	invoke	GetModuleHandle,NULL
	mov	hInstance,eax
	invoke	DialogBoxParam,hInstance,DLG_MAIN,NULL,offset _DialogProc,0	
	invoke	ExitProcess,0
end start
