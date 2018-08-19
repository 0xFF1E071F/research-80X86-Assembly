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
include shell32.inc
include ole32.inc
includelib gdi32.lib
includelib user32.lib
includelib kernel32.lib
includelib comdlg32.lib 
includelib shell32.lib
includelib ole32.lib
;-------------------
; data
;-------------------
				.data?
hInstance	dd	?
hWinMain	dd	?

dwFileSizeHigh	dd	?
dwFileSizeLow	dd	?
dwFileCount	dd	?
dwFolderCount	dd	?

szPath		db	MAX_PATH dup (?)
dwOption	db	?
F_SEARCHING	equ	0001h

		.const
szStart		db	'��ʼ(&S)',0
szStop		db	'ֹͣ(&S)',0
szFilter	db	'*.*',0
szSearchInfo	db	'���ҵ� %d ���ļ��У�%d ���ļ����� %luK �ֽ�',0

szTestFile	db	'E:\fishc\os\helloworld.img',0
szOutputFile	db	'E:\fishc\asm32\21\21.txt',0
szoutputFlag	db	'%d��%d��%d��',0dh,0ah,0

;-------------------
; code
;-------------------
.code
include	_BrowseFolder.asm
_ProcessFile proc _lpFindName
	LOCAL	@hFile
	invoke	CreateFile,_lpFindName,GENERIC_READ,FILE_SHARE_READ,0,OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,0
	
	.if	eax != INVALID_HANDLE_VALUE
		mov	@hFile,eax
		invoke	GetFileSize,eax,0
		add	dwFileSizeLow,eax
		adc 	dwFileSizeHigh,0
		inc	dwFileCount
		invoke	SetDlgItemText,hWinMain,IDC_NOWFILE,_lpFindName
		
		invoke	CloseHandle,@hFile
	.endif
	
	ret
_ProcessFile endp
_FindFile proc _lpszPath
	;invoke MessageBox,NULL,addr szPath,NULL,MB_OK
	LOCAL	@findData:WIN32_FIND_DATA
	LOCAL	@hFile:dword
	LOCAL	@findedName[512]:byte
	LOCAL	@findName[512]:byte
	LOCAL	@szPath[512]:byte
	
	pushad
	;�������·���Ľ�β��'\'�����п����������ģ�c:\windows*.*�Ӷ�ʲôҲ�Ҳ���
	invoke	lstrcpy,addr @szPath,_lpszPath
	invoke	lstrlen,addr @szPath
	lea	esi,@szPath
	add	esi,eax
	xor	eax,eax
	mov	al,'\'
	.if	byte ptr [esi-1] != al
		mov	word ptr [esi],ax
	.endif
	
	;FindFirstFile����Բ���һ���ļ���˵�ģ����ֻ��·�����Ǿ�ֻ���ҵ����·����Ȼ���˳�
	invoke	lstrcpy,addr @findName,addr @szPath
	invoke	lstrcat,addr @findName,addr szFilter
	
	;FindFirstFile �����*.* ��ôһֱ������ֱ���ҵ����з����������ļ����������ȷ�����ļ�����
	;��ô���ҵ�Ŀ���ļ�����˳���
	invoke	FindFirstFile,addr @findName,addr @findData
	.if	eax != INVALID_HANDLE_VALUE
		mov	@hFile,eax
		.repeat
			invoke	lstrcpy,addr @findedName,addr @szPath
			invoke	lstrcat,addr @findedName,addr @findData.cFileName
			
			.if @findData.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY
				;invoke MessageBox,NULL,addr @findedName,NULL,MB_OK
				.if @findData.cFileName != '.' ;����ļ���Ϊ.��˵���ǵ�ǰĿ¼���Ͳ����ٵݹ���
					invoke	_FindFile,addr @findedName
					inc	dwFolderCount
				.endif
			.else
				;invoke	SetDlgItemText,hWinMain,IDC_NOWFILE,addr @findedName
				;invoke MessageBox,NULL,addr @findedName,NULL,MB_OK
				invoke	_ProcessFile,addr @findedName	
			.endif
			invoke	FindNextFile,@hFile,addr @findData
		.until  !eax || !(dwOption & F_SEARCHING)
	.endif
	
	invoke	FindClose,@hFile
	
	;invoke MessageBox,NULL,addr @findedName,NULL,MB_OK	
	
	;!eax ���������
	;or eax,eax 
	;je xx ����xx����Ҫ����ִ�����ĵ�ַ
	
	popad
	ret
_FindFile endp
_ProcThread proc
	;invoke MessageBox,NULL,addr szPath,NULL,MB_OK
	LOCAL	@hPath
	LOCAL	@hBrowse
	LOCAL	@outPutBuf[512]:byte
	
	LOCAL	@writeHFile
	LOCAL	@createTime:FILETIME
	LOCAL	@lastAccessTime:FILETIME
	LOCAL	@lastWriteTime:FILETIME
	LOCAL	@systCreateTime:SYSTEMTIME
	LOCAL	@systLastAccessTime:SYSTEMTIME
	LOCAL	@systLastWriteTime:SYSTEMTIME
	LOCAL	@needWriteNum
	LOCAL	@writeNum
	pushad
	
	invoke	CreateFile,addr szOutputFile,GENERIC_WRITE,0,0,CREATE_ALWAYS,FILE_ATTRIBUTE_NORMAL,0	
	mov	@writeHFile,eax
	invoke	GetFileTime,@writeHFile,addr @createTime,addr @lastAccessTime,addr @lastWriteTime
	invoke	FileTimeToSystemTime,addr @createTime,addr @systCreateTime
	invoke	FileTimeToSystemTime,addr @lastAccessTime,addr @systLastAccessTime
	invoke	FileTimeToSystemTime,addr @lastWriteTime,addr @systLastWriteTime
	
	movzx	eax,@systCreateTime.wDay
	push 	eax
	movzx	eax,@systCreateTime.wMonth
	push 	eax
	movzx	eax,@systCreateTime.wYear
	push	eax
	push	offset szoutputFlag
	lea	eax,@outPutBuf
	push	eax
	call	wsprintf
	add     esp,14h	
	invoke	lstrlen,addr @outPutBuf
	inc	eax
	mov	@needWriteNum,eax
	invoke	WriteFile,@writeHFile,addr @outPutBuf,@needWriteNum,addr @writeNum,0
	
	movzx	eax,@systLastAccessTime.wDay
	push 	eax
	movzx	eax,@systLastAccessTime.wMonth
	push 	eax
	movzx	eax,@systLastAccessTime.wYear
	push	eax
	push	offset szoutputFlag
	lea	eax,@outPutBuf
	push	eax
	call	wsprintf
	add     esp,14h
	invoke	lstrlen,addr @outPutBuf
	inc	eax
	mov	@needWriteNum,eax
	invoke	WriteFile,@writeHFile,addr @outPutBuf,@needWriteNum,addr @writeNum,0
		
	movzx	eax,@systLastWriteTime.wDay
	push 	eax
	movzx	eax,@systLastWriteTime.wMonth
	push 	eax
	movzx	eax,@systLastWriteTime.wYear
	push	eax
	push	offset szoutputFlag
	lea	eax,@outPutBuf
	push	eax
	call	wsprintf
	add         esp,14h
	invoke	lstrlen,addr @outPutBuf
	inc	eax	
	mov	@needWriteNum,eax
	invoke	WriteFile,@writeHFile,addr @outPutBuf,@needWriteNum,addr @writeNum,0
	
	invoke	FlushFileBuffers,@writeHFile			
	invoke	CloseHandle,@writeHFile
	
	invoke	GetDlgItem,hWinMain,IDC_PATH
	mov	@hPath,eax
	invoke  GetDlgItem,hWinMain,IDC_BROWSE
	mov	@hBrowse,eax
	
	invoke	SetDlgItemText,hWinMain,IDOK,addr szStop
	invoke	EnableWindow,@hPath,FALSE
	invoke	EnableWindow,@hBrowse,FALSE
	
	mov	dwFileSizeHigh,0
	mov	dwFileSizeLow,0
	mov	dwFileCount,0
	mov	dwFolderCount,0
	
	invoke  _FindFile,addr szPath
	
	mov	eax,dwFileSizeLow
	mov	edx,dwFileSizeHigh
	mov	ecx,1000
	div	ecx
	invoke	wsprintf,addr @outPutBuf,addr szSearchInfo,dwFileCount,dwFolderCount,eax
	invoke	SetDlgItemText,hWinMain,IDC_NOWFILE,addr @outPutBuf
	
	and dwOption,not F_SEARCHING
	invoke	SetDlgItemText,hWinMain,IDOK,addr szStart
	invoke	EnableWindow,@hPath,TRUE
	invoke	EnableWindow,@hBrowse,TRUE
	
	popad
	ret
_ProcThread endp
_WndProc proc uses edi esi ebx hWnd,uMsg,wParam,lParam
	LOCAL	@stOpenFileName:OPENFILENAME
	LOCAL	@dwTemp:dword
	
	mov eax,uMsg
	.if ax == WM_INITDIALOG
		push hWnd
		pop  hWinMain
	.elseif ax == WM_COMMAND
		mov eax,wParam
		.if ax==IDC_BROWSE
			invoke	_BrowseFolder,hWnd,addr szPath
			.if eax
				invoke SetDlgItemText,hWnd,IDC_PATH,addr szPath
			.endif
		.elseif ax == IDC_PATH
			invoke GetDlgItemText,hWnd,IDC_PATH,addr szPath,MAX_PATH
			mov	ebx,eax
			invoke	GetDlgItem,hWnd,IDOK
			invoke	EnableWindow,eax,ebx
		.elseif ax == IDOK
			.if dwOption & F_SEARCHING
				and dwOption,not F_SEARCHING
			.else
				or dwOption,F_SEARCHING
				invoke GetDlgItemText,hWnd,IDC_PATH,addr szPath,MAX_PATH
				invoke CreateThread,0,0,offset _ProcThread,lParam,0,addr @dwTemp
				invoke CloseHandle,eax
			.endif
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