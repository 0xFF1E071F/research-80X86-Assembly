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

ICO_MAIN	equ	1000
DLG_MAIN	equ	2000
IDC_COUNT	equ	2001
TCP_PORT	equ	9999

		.data?
hModule		dd	?	
hWinMain	dd	?	
szErrBuf	db	512 dup(?)
hSocket		dd	?;����൱��һ��ר�����������ĵ绰��
dwStopListen	dd	?
dwServerThread	dd	?

		.const
szIP		db	'127.0.0.1',0
szStartErr	db	'Init Socket Err',0dh,0ah,0
szAddrErr	db	'inet_addr Err',0dh,0ah,0
szErrCode	db	'%s errorCode is %d',0
szSockErr	db	'socket',0
szBindErr	db	'bind',0
szListenErr	db	'listen',0
szAcceptErr	db	'accept',0
FStop		equ	0001h

		.const
szErrBind	db	'�޷��󶨵�TCP�˿�9999�������Ƿ�������������ʹ��!',0
szSysInfo	db	'ϵͳ��Ϣ',0
szUserLogin	db	' ������������!',0
szUserLogout	db	' �˳���������!',0

;********************************************************************
; �ͻ��˻Ự��Ϣ
;********************************************************************
SESSION		struct
  szUserName	db	12 dup (?)	; �û���
  dwMessageId	dd	?		; �Ѿ��·�����Ϣ���
  dwLastTime	dd	?		; ��·���һ�λ��ʱ��
SESSION		ends

;����
.code

include		_Message.inc
include		_SocketRoute.asm
include		_MsgQueue.asm

;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
; ѭ��ȡ��Ϣ�����е�������䲢���͵��ͻ��ˣ�ֱ��ȫ����Ϣ�������
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
_SendMsgQueue	proc	uses esi edi _hSocket,_lpBuffer,_lpSession
	mov	esi,_lpSession
	mov	edi,_lpBuffer
	assume	esi:ptr SESSION
	assume  edi:ptr MSG_STRUCT
	.while  !(dwStopListen&FStop)
		invoke	_GetMsgFromQueue,[esi].dwMessageId,addr [edi].MsgDown.szSender,addr [edi].MsgDown.szContent
		.break .if !eax
		mov	[esi].dwMessageId,eax
		invoke	lstrlen,addr [edi].MsgDown.szContent
		inc	eax
		mov	[edi].MsgDown.dwLength,eax
		mov	[edi].MsgHead.dwCmdId,CMD_MSG_DOWN
		add	eax,sizeof MSG_HEAD+MSG_DOWN.szContent
		mov	[edi].MsgHead.dwLength,eax
		invoke  send,_hSocket,edi,eax,0
		.break  .if eax==SOCKET_ERROR
		invoke	_WaitData,_hSocket,0
		;�����ȡ���ݵĹ����пͻ��˷����ݹ��������ȴ���ͻ��˵���Ϣ
		.break .if eax>0||eax==SOCKET_ERROR
	.endw
	assume	esi:nothing
	assume  edi:nothing
	ret
_SendMsgQueue	endp

;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
; �����·�����һ�λʱ��
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
_LinkCheck	proc	uses esi edi _hSocket,_lpBuffer,_lpSession
	assume 	esi:ptr MSG_STRUCT
	assume	edi:ptr SESSION
	
	invoke	GetTickCount
	sub	eax,[edi].dwLastTime
	cmp	eax,30*1000
	jb	_LinkCheckEnd
	
	mov	[esi].MsgHead.dwCmdId,CMD_CHECK_LINK
	mov	[esi].MsgHead.dwLength,sizeof MSG_HEAD
	invoke	send,_hSocket,esi,sizeof MSG_HEAD,0
	.if eax==SOCKET_ERROR
		assume	esi:nothing
		assume  edi:nothing
		xor eax,eax	
		ret
	.endif
	
_LinkCheckEnd:
	assume	esi:nothing
	assume  edi:nothing
	mov	eax,1
	ret
_LinkCheck	endp

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

_ServiceThread proc uses ebx edi esi,lParam
	LOCAL	hNewSocket
	LOCAL	@session:SESSION
	LOCAL   serviceBuffer[512]:byte	
	
	push	lParam
	pop	hNewSocket
	
	inc	dwServerThread
	invoke	SetDlgItemInt,hWinMain,IDC_COUNT,dwServerThread,FALSE
	invoke	_WaitData,hNewSocket,200*1000
	cmp 	eax,SOCKET_ERROR
	jz 	serverThreadErr
	invoke	_RecvPacket,hNewSocket,addr serviceBuffer,sizeof serviceBuffer
	cmp	eax,0
	jnz	serverThreadErr
	
	lea	edi,@session
	lea	esi,serviceBuffer
	assume 	esi:ptr MSG_STRUCT
	assume	edi:ptr SESSION

	cmp	[esi].MsgHead.dwCmdId,CMD_LOGIN
	jne	serverThreadErr
	invoke	lstrcpy,addr [edi].szUserName,addr [esi].Login.szUserName
	push	dwSequence
	pop	@session.dwMessageId
	mov	[esi].MsgHead.dwCmdId,CMD_LOGIN_RESP
	mov	[esi].LoginResp.dbResult,0 ;������Զ�ȡ���ݿ�ʲô�ģ�������ܲ��ԣ�������1
	mov	[esi].MsgHead.dwLength,sizeof MSG_HEAD+sizeof MSG_LOGIN_RESP
	invoke	send,hNewSocket,addr serviceBuffer,[esi].MsgHead.dwLength,0
	
	cmp	[esi].LoginResp.dbResult,0 ;��½ʧ��
	jnz	serverThreadErr
	
	;����㲥
	invoke	lstrcpy,esi,addr [edi].szUserName
	invoke	lstrcat,esi,offset szUserLogin
	invoke	_InsertMsgQueue,addr szSysInfo,addr serviceBuffer
	
	invoke	GetTickCount
	mov	[edi].dwLastTime,eax
	
	.while	!(dwStopListen&FStop)
		invoke	_LinkCheck,hNewSocket,esi,edi
		.break .if !eax
		
		invoke	_SendMsgQueue,hNewSocket,esi,addr @session
		invoke	_WaitData,hNewSocket,200*1000
		.if eax==SOCKET_ERROR
			.break
		.endif
		.if 	eax
			invoke	_RecvPacket,hNewSocket,addr serviceBuffer,sizeof serviceBuffer
			.break	.if eax
			invoke	GetTickCount
			mov	[edi].dwLastTime,eax
			.if	[esi].MsgHead.dwCmdId == CMD_MSG_UP
				invoke	_InsertMsgQueue,addr [edi].szUserName,addr [esi].MsgUp.szContent
			.endif 
 		.endif
	.endw
	
	;�˳��㲥
	invoke	lstrcpy,addr serviceBuffer,addr @session.szUserName
	invoke	lstrcat,addr serviceBuffer,offset szUserLogout
	invoke	_InsertMsgQueue,addr szSysInfo,addr serviceBuffer
	
serverThreadErr:
	assume 	esi:nothing
	assume	edi:nothing
	invoke	closesocket,hNewSocket
	dec	dwServerThread
	invoke	SetDlgItemInt,hWinMain,IDC_COUNT,dwServerThread,FALSE
	ret
_ServiceThread endp

_ListenThread proc
	LOCAL	sin:sockaddr_in
	LOCAL	newSin:sockaddr_in
	LOCAL	newSinLen
	
	;����sockaddr_in
	invoke	RtlZeroMemory,addr sin,sizeof sockaddr_in
	mov	sin.sin_family,AF_INET
	mov	sin.sin_addr,INADDR_ANY	;������кö�̨�绰
	invoke	htons,TCP_PORT
	mov	sin.sin_port,ax
	
	;�׽��֣�����ͨ�ŵĶ���,������Ϊͨ�ŵ�һ��,����һ�˱�������һ���׽��֣����ܽ���ͨ��
	;�׽��ַ�Ϊ���֣����׽��֣����ݱ��׽���
	invoke	socket,AF_INET,SOCK_STREAM,0
	.if	eax==INVALID_SOCKET
		invoke	_ShowErrCode,addr szSockErr
		invoke	WSACleanup
		ret
	.endif
	mov	hSocket,eax
	
	invoke	bind,hSocket,addr sin,sizeof sin
	;������
	;WSAEADDRINUSE	�˿��Ѿ�����ʹ��       �õ�ַ�Ѿ����������ù��ˣ�һ̨�绰��ֻ�ܱ�һ������
	;WSAEFAULT	�˿��Ѿ��󶨹�һ����   �Ѿ�ע���һ�ε�ַ��
	.if	eax==SOCKET_ERROR
		invoke	_ShowErrCode,addr szBindErr
		invoke	closesocket,hSocket
		invoke	WSACleanup
	.endif
	
	invoke	listen,hSocket,3
	;������
	;WSAEINVAL	��û��bind�ͽ��м��� û��ע��һ��׼ȷ�ĵ�ַ������׼�����绰
	.if	eax==SOCKET_ERROR
		invoke	_ShowErrCode,addr szListenErr
		invoke	closesocket,hSocket
		invoke	WSACleanup
		ret
	.endif
	
	.while	!(dwStopListen&FStop)
		mov	newSinLen,sizeof newSin
		invoke	RtlZeroMemory,addr newSin,newSinLen
		invoke	accept,hSocket,addr newSin,addr newSinLen
		.if	eax==INVALID_SOCKET
			invoke	_ShowErrCode,addr szAcceptErr
			invoke	closesocket,hSocket
			invoke	WSACleanup
			.break
		.endif
		invoke	CreateThread,0,0,offset _ServiceThread,eax,0,0
		invoke	CloseHandle,eax
	.endw
	
	ret
_ListenThread endp

_DialogProc proc hWnd,uMsg,wParam,lParam
	LOCAL	wVersionRequested
	LOCAL	wsaData:WSADATA
	
	mov	eax,uMsg
;********************************************************************
	.if	eax ==	WM_INITDIALOG
		push	hWnd
		pop	hWinMain
		
		invoke	InitializeCriticalSection,addr stCS
		
		;��ʼ��
		mov	wVersionRequested,101h
		invoke	WSAStartup,wVersionRequested,addr wsaData
		.if	eax
			invoke	_WriteConsole,addr szStartErr,0
			jmp	dlgEnd
		.endif
		invoke	CreateThread,0,0,offset _ListenThread,0,0,0
		invoke	CloseHandle,eax
;********************************************************************
	.elseif	eax ==	WM_CLOSE
		or	dwStopListen,FStop
		invoke	closesocket,hSocket
		.while	dwServerThread
		.endw
		invoke	DeleteCriticalSection,addr stCS
		invoke	WSACleanup
		invoke	EndDialog,hWinMain,NULL
;********************************************************************
	.else
		mov	eax,FALSE
		ret
	.endif

dlgEnd:
	mov	eax,TRUE
	ret	
_DialogProc endp

start:
	invoke	GetModuleHandle,NULL
	mov	hModule,eax
	invoke	DialogBoxParam,hModule,DLG_MAIN,NULL,offset _DialogProc,0
	invoke	ExitProcess,NULL
end start
