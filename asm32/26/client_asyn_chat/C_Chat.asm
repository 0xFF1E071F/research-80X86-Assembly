.386
.model flat,stdcall
option casemap:none
;Ԥ����

;ͷ�ļ�
include		windows.inc   	;��������
include		kernel32.inc  	;GetModuleHandle ExitProcess �Ķ���
includelib	kernel32.lib	
include		user32.inc	;EndDialog DialogBoxParam �Ķ���
includelib	user32.lib
include		ws2_32.inc
includelib	ws2_32.lib
include		_Message.inc

		.data?
szErrBuf	db	512 dup(?)

hInstance	dd	?
hWinMain	dd	?
hSocket		dd	?
hLogin		dd	?
hLoginOut	dd	?
hInputText	dd	?
hSendBtn	dd	?
dwLastTime	dd	?
szServer	db	16 dup (?)
szUserName	db	12 dup (?)
szPassword	db	12 dup (?)
szText		db	256 dup (?)

szSendMsg	MSG_STRUCT 10 dup (<>)
szRecvMsg	MSG_STRUCT 10 dup (<>)
dwSendBufSize	dd	?
dwRecvBufSize	dd	?
dbStep		db	?

		.const
szIP		db	'127.0.0.1',0
szStartErr	db	'Init Socket Err',0
szAddrErr	db	'inet_addr Err',0
szErrCode	db	'%s errorCode is %d',0
szSendFmt	db	'hello world %d',0dh,0ah,0
szSockErr	db	'socket',0
szConnErr	db	'connect',0
szSendErr	db	'send',0

szErrIP		db	'��Ч�ķ�����IP��ַ!',0
szErrConnect	db	'�޷����ӵ�������!',0
szErrLogin	db	'�޷���¼���������������û�������!',0
szSpar		db	' : ',0

;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
;	equ ����
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
ICO_MAIN	equ	1000
DLG_MAIN	equ	2000
IDC_SERVER	equ	2001
IDC_USER	equ	2002
IDC_PASS	equ	2003
IDC_LOGIN	equ	2004
IDC_LOGOUT	equ	2005
IDC_INFO	equ	2006
IDC_TEXT	equ	2007
TCP_PORT	equ	9999
WM_SOCKET       equ	WM_USER + 100

;����
.code

_WriteConsole	proc	lpWriteBuffer,dwWriteBytes
	invoke	MessageBox,NULL,lpWriteBuffer,NULL,MB_OK
	ret
_WriteConsole 	endp

_WriteEnter	proc
	ret
_WriteEnter endp

_ShowErrCode proc lpTypeStr
	invoke	WSAGetLastError
	invoke	wsprintf,addr szErrBuf,addr szErrCode,lpTypeStr,eax
	invoke	_WriteConsole,addr szErrBuf,0
	invoke	_WriteEnter
	ret
_ShowErrCode endp

;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
; �Ͽ�����
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
_DisConnect	proc

	invoke	EnableWindow,hLogin,TRUE
	invoke	EnableWindow,hLoginOut,FALSE
	invoke	EnableWindow,hInputText,FALSE

	.if hSocket
		invoke	closesocket,hSocket
		mov	hSocket,0
	.endif
	ret
_DisConnect	endp
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
; ���ӵ�������
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
_Connect	proc
	LOCAL	sin:sockaddr_in
	
	;����sockaddr_in
	invoke	RtlZeroMemory,addr sin,sizeof sockaddr_in
	mov	sin.sin_family,AF_INET
	invoke	inet_addr,addr szServer
	.if	eax==INADDR_NONE
		invoke	_WriteConsole,addr szAddrErr,0
		jmp	_ConnectEnd
	.endif
	mov	sin.sin_addr,eax
	invoke	htons,9999
	mov	sin.sin_port,ax
	
	;�׽��֣�����ͨ�ŵĶ���,������Ϊͨ�ŵ�һ��,����һ�˱�������һ���׽��֣����ܽ���ͨ��
	;�׽��ַ�Ϊ���֣����׽��֣����ݱ��׽���
	invoke	socket,AF_INET,SOCK_STREAM,IPPROTO_TCP
	.if	eax==INVALID_SOCKET
		invoke	_ShowErrCode,addr szSockErr
		jmp	_ConnectEnd
	.endif
	mov	hSocket,eax
	
	;�Է�����ģʽ���ӷ�����
	invoke	WSAAsyncSelect,hSocket,hWinMain,WM_SOCKET,FD_READ or FD_WRITE or FD_CONNECT or FD_CLOSE
	invoke	connect,hSocket,addr sin,sizeof sin
	;������
	;WSAECONNREFUSED ������û����ָ���Ķ˿ڼ������绰�ڣ������˲��ڵ绰�Ա�
	;WSAETIMEOUT	 ���粻ͨ�������������ߣ�    �绰���ڣ�����ǿպ�
	;WSAEWOULDBLOCK	 �������ӣ�����ȴ�,         �绰����������
	.if	eax==SOCKET_ERROR
		invoke	WSAGetLastError
		.if	eax!=WSAEWOULDBLOCK
			invoke	_ShowErrCode,addr szConnErr
			jmp	_ConnectEnd
		.endif
	.endif
	
	ret
	
_ConnectEnd:
	.if hSocket
		invoke	CloseHandle,hSocket
		mov	hSocket,0
	.endif
	ret
_Connect	endp
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
; ���ͻ������е����ݣ��ϴε������п���δ�����꣬��ÿ�η���ǰ��
; �Ƚ����ͻ������ϲ�
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
_SendData	proc	_lpData,_dwSize
	pushad
	mov	esi,_lpData
	mov	ecx,_dwSize
	
	.if	esi && ecx
		lea	edi,szSendMsg
		add	edi,dwSendBufSize
		cld
		rep	movsb
		mov	ecx,_dwSize
		add	dwSendBufSize,ecx
	.endif
	
	cmp	dwSendBufSize,0
	jz	_SendDataEnd
	mov	ecx,dwSendBufSize
	lea	esi,szSendMsg
@@:
	invoke	send,hSocket,esi,ecx,0
	.if	eax==SOCKET_ERROR
		invoke	WSAGetLastError
		.if	eax!=WSAEWOULDBLOCK
			invoke	_DisConnect
		.endif
		jmp	_SendDataEnd
	.endif
	sub	dwSendBufSize,eax
	jz	_SendDataEnd
	.if	eax!=0 ;�����������Ϊ0��˵���������Ѿ����ˣ����´��յ�FD_WRITEʱ�ٷ����ȴ��Ļ�����Ӱ�������Ӧ
		mov	ecx,dwSendBufSize
		add	esi,eax
		jmp	@B
	.endif
_SendDataEnd:
	popad
	ret
_SendData	endp
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
; ������Ϣ
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
_ProcMessage	proc
	LOCAL	@szBuffer[512]:byte
	pushad
	assume	esi:ptr MSG_STRUCT
	lea	esi,szRecvMsg
	mov	ax,[esi].MsgHead.dwCmdId
	.if	ax==CMD_LOGIN_RESP
		.if	[esi].LoginResp.dbResult!=0
			invoke	EnableWindow,hLogin,TRUE
			invoke	EnableWindow,hLoginOut,FALSE
			invoke	EnableWindow,hInputText,FALSE
			invoke	_DisConnect
		.else
			invoke	EnableWindow,hLogin,FALSE
			invoke	EnableWindow,hLoginOut,TRUE
			invoke	EnableWindow,hInputText,TRUE
		.endif
	.elseif	ax==CMD_MSG_DOWN
		invoke	lstrcpy,addr @szBuffer,addr [esi].MsgDown.szSender
		invoke	lstrcat,addr @szBuffer,addr szSpar
		invoke	lstrcat,addr @szBuffer,addr [esi].MsgDown.szContent
		invoke	SendDlgItemMessage,hWinMain,IDC_INFO,LB_INSERTSTRING,0,addr @szBuffer
	.endif
	
_ProcMessageEnd:
	popad	
	assume	esi:nothing
	ret
_ProcMessage	endp
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
; �������ݰ�
; �첽�Ķ�ȡ�����Լ�ȥѭ����ȡ������������������ݣ���һֱ��FD_READ��Ϣ
; ����ͬ���ı����Լ�ѭ������ֱ��������û�����ݶ�Ϊֹ��������д���������첽����
; ͬ�����������Լ�ȥд����Ϊֻ��ֻ�����Լ���֪��Ҫд���٣�
; ���������д�Ĺ����У������˴��󣬻���ֹд�Ĺ���,ͬ��������£�Ҫ���Լ�����
; ��ȥѯ�ʿ���д��û������д��û�����첽������£�����FD_WRITE����Ϣ֪ͨ,����
; �ܽ�һ�㣬ͬ��������£���select����ѭ�����ϵ�ѯ�ʿ���д�����û�����첽�������
; ����ϵͳ��Ϣ֪ͨ
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
_RecvData	proc

	;szRecvMsg	��ȡ����
	;dwRecvBufSize	��¼�ϴζ��˶�������,Ϊ0��ʾ���¿�ʼ��һ��Э��

	pushad
	lea	esi,szRecvMsg
	assume  esi:ptr MSG_STRUCT
	
	.if	dwRecvBufSize==0
		mov	eax,sizeof MSG_HEAD
	.elseif	dwRecvBufSize<sizeof MSG_HEAD
		mov	eax,sizeof MSG_HEAD
		sub	eax,dwRecvBufSize
	.else
		mov	eax,[esi].MsgHead.dwLength
		sub	eax,dwRecvBufSize
	.endif
	add	esi,dwRecvBufSize
	invoke	recv,hSocket,esi,eax,0
	.if	eax==SOCKET_ERROR
		invoke	WSAGetLastError
		.if	eax!=WSAEWOULDBLOCK
			invoke	_DisConnect
		.endif
		jmp _RecvDataEnd
	.endif
	add	dwRecvBufSize,eax
	.if	dwRecvBufSize>=sizeof MSG_HEAD
		mov	eax,szRecvMsg.MsgHead.dwLength
		.if	eax==dwRecvBufSize
			invoke	_ProcMessage
			mov	dwRecvBufSize,0
		.endif
	.endif
_RecvDataEnd:
	assume  esi:nothing
	popad
	ret
_RecvData	endp

;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
; �����ڳ���
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
_ProcDlgMain	proc	uses ebx edi esi hWnd,wMsg,wParam,lParam
		local	@stWsa:WSADATA,@stMsg:MSG_STRUCT
	
		mov	eax,wMsg
		.if	eax==WM_SOCKET
			mov	eax,lParam
			.if	ax==FD_READ
				invoke	_RecvData
			.elseif	ax==FD_WRITE
				invoke	_SendData,0,0
			.elseif ax==FD_CONNECT
				shr	eax,16
				.if	ax==0
					;���ӳɹ��󣬷��͵�½����
					mov	@stMsg.MsgHead.dwCmdId,CMD_LOGIN
					mov	@stMsg.MsgHead.dwLength,sizeof MSG_HEAD+sizeof MSG_LOGIN
					invoke	lstrcpy,addr @stMsg.Login.szUserName,addr szUserName
					invoke	lstrcpy,addr @stMsg.Login.szPassword,addr szPassword
					invoke	_SendData,addr @stMsg,@stMsg.MsgHead.dwLength
				.else
					invoke	_ShowErrCode,addr szConnErr
					invoke	_DisConnect
				.endif
			.elseif ax==FD_CLOSE
				invoke	_DisConnect
			.endif
;********************************************************************
		.elseif	eax ==	WM_COMMAND
			mov	eax,wParam
;********************************************************************
; ȫ������IP��ַ���û�����������򼤻�"��¼"��ť
;********************************************************************
			.if	(ax == IDC_SERVER) || (ax == IDC_USER) || (ax == IDC_PASS)
				invoke	GetDlgItemText,hWnd,IDC_SERVER,addr szServer,sizeof szServer
				invoke	GetDlgItemText,hWnd,IDC_USER,addr szUserName,sizeof szUserName
				invoke	GetDlgItemText,hWnd,IDC_PASS,addr szPassword,sizeof szPassword
				.if	szServer&&szUserName&&szPassword&& !hSocket
					invoke	EnableWindow,hLogin,TRUE
				.else
					invoke	EnableWindow,hLogin,FALSE
				.endif
;********************************************************************
; ��¼�ɹ���������������ż���"����"��ť
;********************************************************************
			.elseif	ax ==	IDC_TEXT
				invoke	GetWindowText,hInputText,addr szText,sizeof szText
				.if	szText && hSocket
					invoke	EnableWindow,hSendBtn,TRUE
				.else
					invoke	EnableWindow,hSendBtn,FALSE				
				.endif
;********************************************************************
			.elseif	ax ==	IDC_LOGIN
				invoke	_Connect
				invoke	EnableWindow,hLogin,FALSE
;********************************************************************
			.elseif	ax ==	IDC_LOGOUT
				invoke	_DisConnect
;********************************************************************
			.elseif	ax ==	IDOK
				mov	@stMsg.MsgHead.dwCmdId,CMD_MSG_UP
				invoke	lstrcpy,addr @stMsg.MsgUp.szContent,addr szText
				invoke	lstrlen,addr szText
				inc	eax
				mov	@stMsg.MsgUp.dwLength,eax
				add	eax,sizeof MSG_HEAD+MSG_UP.szContent
				mov	@stMsg.MsgHead.dwLength,eax
				invoke	_SendData,addr @stMsg,eax
				invoke	SetDlgItemText,hWnd,IDC_TEXT,NULL
				invoke	RtlZeroMemory,addr szText,sizeof szText
			.endif
;********************************************************************
		.elseif	eax ==	WM_CLOSE
			invoke	_DisConnect
			invoke	WSACleanup
			invoke  EndDialog,hWnd,0
;********************************************************************
		.elseif	eax ==	WM_INITDIALOG
			push	hWnd
			pop	hWinMain
			invoke	LoadIcon,hInstance,ICO_MAIN
			invoke	SendMessage,hWnd,WM_SETICON,ICON_BIG,eax
			invoke	GetDlgItem,hWnd,IDC_LOGIN
			mov	hLogin,eax
			invoke	GetDlgItem,hWnd,IDC_LOGOUT
			mov	hLoginOut,eax
			invoke	GetDlgItem,hWnd,IDC_TEXT
			mov	hInputText,eax
			invoke	GetDlgItem,hWnd,IDOK
			mov	hSendBtn,eax
			invoke	EnableWindow,hLogin,FALSE
			invoke	EnableWindow,hLoginOut,FALSE
			
			invoke	WSAStartup,101h,addr @stWsa
			.if	eax
				invoke	_WriteConsole,addr szStartErr,0
			.endif
			
;********************************************************************
		.else
			mov	eax,FALSE
			ret
		.endif
		mov	eax,TRUE
		ret

_ProcDlgMain	endp

start:
	invoke	GetModuleHandle,NULL
	mov	hInstance,eax
	invoke	DialogBoxParam,eax,DLG_MAIN,NULL,offset _ProcDlgMain,NULL
	invoke	ExitProcess,NULL
end start
