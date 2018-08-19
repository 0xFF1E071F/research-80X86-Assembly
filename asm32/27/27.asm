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
szMsg		db	"�쳣����λ��:%08X��%08X���쳣����:%08X����־��%08X",0
szSafe		db	"�ص��˰�ȫ�ĵط�",0
szTitle		db	"ɸѡ���쳣���������",0
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
;�����
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
.code
_Handler	proc	_lpExceptionPoint
		LOCAL 	@szBuffer[256]:byte
		pushad
		mov	esi,_lpExceptionPoint
		assume	esi:ptr	EXCEPTION_POINTERS
		mov	edi,[esi].ContextRecord
		mov	esi,[esi].pExceptionRecord
		assume	esi:ptr	EXCEPTION_RECORD,edi:ptr CONTEXT
		mov	eax,[esi].ExceptionFlags
		;�����־����λ��˵���쳣�������ģ�Ӧ���˳�
		and	eax,00000001h
		.if	eax==1
			mov	eax,EXCEPTION_CONTINUE_SEARCH
			ret
		.endif
		;ExceptionCode�а����ˣ��쳣�����ͣ������ԣ������쳣�����ã����ڴ�
		;�������磬����CPU�����ǽӿڿ������Ƕ�ý������
		;ExceptionFlag��ָ�����쳣�Ƿ��³������ֹ
		invoke	wsprintf,addr @szBuffer,addr szMsg,\
			[edi].regEip,[esi].ExceptionAddress,[esi].ExceptionCode,[esi].ExceptionFlags
		invoke	MessageBox,NULL,addr @szBuffer,NULL,MB_OK
		mov	[edi].regEip,offset _SafePlace
		assume	esi:nothing,edi:nothing
		popad	
		;����ֵ������ExceptionFlag�������Ƿ�Ӧ���ó��������ȥ
		mov	eax,EXCEPTION_CONTINUE_EXECUTION
		ret
_Handler endp

start:
	invoke	SetUnhandledExceptionFilter,addr _Handler
	mov	lpOldHandler,eax
	xor 	eax,eax
	mov	dword ptr [eax],0
_SafePlace:
	invoke	MessageBox,NULL,addr szSafe,addr szTitle,MB_OK
	invoke	ExitProcess,NULL
end start