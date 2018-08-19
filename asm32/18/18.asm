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
include comdlg32.inc
includelib gdi32.lib
includelib user32.lib
includelib kernel32.lib
includelib comdlg32.lib 
;-------------------
; data
;-------------------
		.data?
hInstance	dd	?
hWinMain	dd	?
szFileName	db	MAX_PATH dup (?)

		.const
szFileExt	db	'�ı��ļ�',0,'*.txt',0,0
szNewFile	db	'.new.txt',0
szErrOpenFile	db	'�޷���Դ�ļ�!',0
szErrCreateFile	db	'�޷������µ��ı��ļ�!',0
szSuccees	db	'�ļ�ת���ɹ����µ��ı��ļ�����Ϊ',0dh,0ah,'%s',0
szSucceesCap	db	'��ʾ',0
szMsgTemp	db	'%d',0
;-------------------
; code
;-------------------
.code
_FormatText proc _lpData,_dwSize,_hFile
	
	;LOCAL	msg[256]:byte
	;invoke	wsprintf,addr msg,addr szMsgTemp,_dwSize
	;invoke	MessageBox,NULL,addr msg,NULL,MB_OK
	
	LOCAL	writeBuf[256]:byte
	LOCAL	writeNum:dword
	pushad
	
	mov ecx,_dwSize
	mov esi,_lpData
	lea edi,writeBuf
	xor edx,edx
nextByte:	
	xor eax,eax
	lodsb
	cmp eax,0Ah
	jne @F
	mov eax,0A0Dh
	stosw
	add edx,2
	sub ecx,2
	jmp isNeedWrite
@@:	
	stosb
	dec ecx
	inc edx
isNeedWrite:
	cmp ecx,0
	je writeBegin
	cmp edx,sizeof writeBuf-2
	jae writeBegin
	jmp nextByte	
writeBegin:
	push	ecx
	invoke	WriteFile,_hFile,addr writeBuf,edx,addr writeNum,0
	invoke	FlushFileBuffers,_hFile
	xor	edx,edx
	lea	edi,writeBuf
	pop	ecx
	cmp	ecx,0
	jne 	nextByte
	
	popad
	ret

_FormatText endp
_ProcFile proc
	
	LOCAL	@szFileNameNew[MAX_PATH]:byte
	LOCAL	@whFile:dword
	LOCAL	@rhFile:dword
	LOCAL	@readBuf[512]:byte
	LOCAL	@numRead:dword
	LOCAL	@succeedWord[256]:byte
	
	; ���ļ�
	; lpSecurityAttributes �Ƿ������ӽ��̼̳о��,hTemplateFile �ļ�ģ����,��������������ݿ��������ļ����
	invoke	CreateFile,addr szFileName,GENERIC_READ,FILE_SHARE_READ,0,OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,0
	.if	eax == INVALID_HANDLE_VALUE 
		invoke	MessageBox,NULL,addr szErrOpenFile,NULL,MB_OK
		ret
	.endif
	mov	@rhFile,eax
	invoke	lstrcpy,addr @szFileNameNew,addr szFileName
	invoke	lstrcat,addr @szFileNameNew,addr szNewFile
	invoke	CreateFile,addr @szFileNameNew,GENERIC_WRITE,0,0,CREATE_ALWAYS,FILE_ATTRIBUTE_NORMAL,0
	.if	eax == INVALID_HANDLE_VALUE
		invoke	MessageBox,NULL,addr szErrCreateFile,NULL,MB_OK
		invoke	CloseHandle,@rhFile
		ret
	.endif
	mov	@whFile,eax
	.while TRUE
		;lpOverlapp �첽���ļ�ʱʹ��
		lea	esi,@readBuf
		invoke	ReadFile,@rhFile,esi,sizeof @readBuf,addr @numRead,0
		.break .if ! @numRead
		invoke  _FormatText,esi,@numRead,@whFile
	.endw
	invoke	CloseHandle,@rhFile
	invoke	CloseHandle,@whFile
	invoke	wsprintf,addr @succeedWord,addr szSuccees,addr @szFileNameNew
	invoke	MessageBox,NULL,addr @succeedWord,addr szSucceesCap,MB_OK
	ret

_ProcFile endp
_WndProc proc uses edi esi ebx hWnd,uMsg,wParam,lParam
	LOCAL	@stOpenFileName:OPENFILENAME
	
	mov eax,uMsg
	.if ax == WM_INITDIALOG
		push hWnd
		pop  hWinMain
	.elseif ax == WM_COMMAND
		mov eax,wParam
		.if ax==IDC_BROWSE
			invoke	RtlZeroMemory,addr @stOpenFileName,sizeof OPENFILENAME
			mov	@stOpenFileName.lStructSize,sizeof OPENFILENAME
			mov	@stOpenFileName.Flags,\
				OFN_FILEMUSTEXIST or OFN_PATHMUSTEXIST
			push	hWinMain
			pop	@stOpenFileName.hwndOwner
			mov	@stOpenFileName.lpstrFilter,offset szFileExt
			mov	@stOpenFileName.lpstrFile,offset szFileName
			mov	@stOpenFileName.nMaxFile,MAX_PATH
			invoke	GetOpenFileName,addr @stOpenFileName
			.if 	eax
				invoke	SetDlgItemText,hWnd,IDC_FILE,addr szFileName
			.endif
		.elseif ax == IDC_FILE
			invoke GetDlgItemText,hWnd,IDC_FILE,addr szFileName,MAX_PATH
			mov	ebx,eax
			invoke	GetDlgItem,hWnd,IDOK
			invoke	EnableWindow,eax,ebx
		.elseif ax == IDOK
			call _ProcFile
		.endif
	.elseif ax == WM_CLOSE
		invoke EndDialog,hWnd,NULL
	.else
		mov eax,FALSE
		ret
	.endif
	mov eax,TRUE
	ret

_WndProc endp ;������һ�䣬ֻҪ��ret�ĵط����ᱻ��չΪ
;pop esi �ָ��Ĵ���
;mov esp,ebp
;pop ebp
;retn xx Ĭ���������ʹ��stdcall �����߸����ջƽ��
_MainProc proc
	invoke	DialogBoxParam,hInstance,DLG_MAIN,NULL,addr _WndProc,0
	ret
_MainProc endp

start:
	invoke	GetModuleHandle,NULL
	mov	hInstance,eax	
	invoke	_MainProc
	invoke	ExitProcess,NULL
end start	