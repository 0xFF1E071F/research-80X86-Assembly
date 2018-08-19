.386
.model 	flat,stdcall
option 	casemap:none
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
;include
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
include 	windows.inc
include 	user32.inc
includelib	user32.lib
include 	kernel32.inc
includelib 	kernel32.lib
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
;���ݶ�
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
.data
lpOldHandler	dd	?
.const
szMsg		db	"���쳣����λ��:%08X���쳣����:%08X����־��%08X",0
szInMsg		db	"���쳣����λ��:%08X���쳣����:%08X����־��%08X",0
szSafe		db	"�ص����ⰲȫ�ĵط�",0
szInSafe	db	"�ص����ڰ�ȫ�ĵط�",0
szTitle		db	"SEH������",0
szFSMsg		db	"FS:[0] %08X",0
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
;�����
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
.code

_InTest	proc
	assume	fs:nothing
	push	ebp
	push	offset _InSafePlace
	push	offset _InHandler
	push	fs:[0]
	mov	fs:[0],esp

	xor 	eax,eax
	mov	dword ptr [eax],0
	
_InSafePlace:
	invoke	MessageBox,NULL,addr szInSafe,addr szTitle,MB_OK
	pop	fs:[0]
	add	esp,0ch	
	ret

_InTest endp

_InHandler	proc	c _lpExceptionRecord,_lpSEH,_lpContext,_lpDispatcherContext
		LOCAL 	@szBuffer[1024]:byte
		pushad
		
		mov	esi,_lpExceptionRecord
		mov	edi,_lpContext
		assume	esi:ptr	EXCEPTION_RECORD,edi:ptr CONTEXT
		mov	eax,[esi].ExceptionCode
		
		;ExceptionCode�а����ˣ��쳣�����ͣ������ԣ������쳣�����ã����ڴ�
		;�������磬����CPU�����ǽӿڿ������Ƕ�ý���豸
		;ExceptionFlag ��ɶ�ã�
		invoke	wsprintf,addr @szBuffer,addr szInMsg,\
			[edi].regEip,[esi].ExceptionCode,[esi].ExceptionFlags
		invoke	MessageBox,NULL,addr @szBuffer,NULL,MB_OK
		
		popad
		mov	eax,ExceptionContinueSearch
		
		assume	esi:nothing,edi:nothing
		ret
_InHandler 	endp

_Handler	proc	c _lpExceptionRecord,_lpSEH,_lpContext,_lpDispatcherContext
		LOCAL 	@szBuffer[1024]:byte
		pushad
		
		mov	esi,_lpExceptionRecord
		mov	edi,_lpContext
		assume	esi:ptr	EXCEPTION_RECORD,edi:ptr CONTEXT
		mov	eax,[esi].ExceptionCode
		
		;����ջչ��������������
		.if 	eax == STATUS_UNWIND
			popad
			mov	eax,ExceptionContinueSearch
		;���ʷǷ�
		.elseif eax == EXCEPTION_ACCESS_VIOLATION
			;ExceptionCode�а����ˣ��쳣�����ͣ������ԣ������쳣�����ã����ڴ�
			;�������磬����CPU�����ǽӿڿ������Ƕ�ý������
			;ExceptionFlag ��ʶ��������ִ�У�����ջչ����
			invoke	wsprintf,addr @szBuffer,addr szMsg,\
				[edi].regEip,[esi].ExceptionCode,[esi].ExceptionFlags
			invoke	MessageBox,NULL,addr @szBuffer,NULL,MB_OK
		
			mov	eax,_lpSEH
		
			push	[eax+0ch]
			pop	[edi].regEbp
			push	[eax+8]
			pop	[edi].regEip
			push	eax
			pop	[edi].regEsp
			
			invoke	wsprintf,addr @szBuffer,addr szFSMsg,dword ptr fs:[0]
			invoke	MessageBox,NULL,addr @szBuffer,NULL,MB_OK
			invoke	RtlUnwind,_lpSEH,NULL,NULL,NULL
			invoke	wsprintf,addr @szBuffer,addr szFSMsg,dword ptr fs:[0]
			invoke	MessageBox,NULL,addr @szBuffer,NULL,MB_OK
			popad
			mov	eax,ExceptionContinueExecution
		.else
			popad
			mov	eax,ExceptionContinueSearch		
		.endif
		
		assume	esi:nothing,edi:nothing
		ret
_Handler 	endp

_Test		proc
	assume	fs:nothing
	push	ebp
	push	offset _SafePlace
	push	offset _Handler
	;fs:[0]��������EXCEPTION_REGISTRATION�ṹ�ĵ�ַ
	push	fs:[0]
	;�޸���fs:[0]��ָ��ջ�е�ǰ8���ֶθպ��Ǻ���EXCEPTION_REGISTRATION�ṹ�е�ExceptionList�ֶ�
	mov	fs:[0],esp

	invoke 	_InTest
	
_SafePlace:
	invoke	MessageBox,NULL,addr szSafe,addr szTitle,MB_OK
	pop	fs:[0]
	add	esp,0ch	
	ret
_Test	endp

start:
	invoke	_Test
	invoke	ExitProcess,NULL
end start