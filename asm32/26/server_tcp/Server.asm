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
include		InitConsole.asm
include		ws2_32.inc
includelib	ws2_32.lib
		.data?
szErrBuf	db	512 dup(?)
szRecvBuf	db	20  dup(?)
		.const
szIP		db	'127.0.0.1',0
szStartErr	db	'Init Socket Err',0dh,0ah,0
szAddrErr	db	'inet_addr Err',0dh,0ah,0
szErrCode	db	'%s errorCode is %d',0
szSockErr	db	'socket',0
szBindErr	db	'bind',0
szListenErr	db	'listen',0
szAcceptErr	db	'accept',0
;����
.code

_ShowErrCode proc lpTypeStr
	invoke	WSAGetLastError
	invoke	wsprintf,addr szErrBuf,addr szErrCode,lpTypeStr,eax
	invoke	_WriteConsole,addr szErrBuf,0
	invoke	_WriteEnter
	ret
_ShowErrCode endp

_NewThread proc uses ebx edi esi,lParam
	LOCAL	hNewSocket
	push	lParam
	pop	hNewSocket
	.while	TRUE
		invoke	recv,hNewSocket,addr szRecvBuf,sizeof szRecvBuf,0
		;����socket_errorʱ����������Ϊ�ͻ������������ر�socket,�������رյ�ʱ�򣬻᷵��
		;0,�Ӷ���ַѭ������������ͻ��ˣ���Ϊ����ԭ��û�з��͹رյķ�����Ϣ����ô��������
		;����socket_error��Ϣ���Ӷ���ַѭ�����ͻ��ˣ������ڻ�������������ֱ���ֵ���Ƿ����ǣ�
		;���Ǹ�����ֵ���պ���socket������Ӷ�ʹ��socket��Ч�������쳣�˳��ˣ���ʱ��û�з���
		;������Ϣ��������
		.if	eax==SOCKET_ERROR
			invoke	WSAGetLastError
			.if	eax!=WSAEWOULDBLOCK
				.break
			.endif
		.endif
		.break	.if !eax ;�Ѿ�û�л������ѿ�
		invoke	_WriteConsole,addr szRecvBuf,eax
		;��TCPЭ����RST��ʾ��λ�������쳣�Ĺر����ӣ���TCP����������ǲ��ɻ�ȱ�ġ�
		;����RST���ر�����ʱ�����صȻ������İ�������ȥ��ֱ�ӾͶ����������İ�����RST����
		;�����ն��յ�RST����Ҳ���ط���ACK����ȷ�ϡ� 
		;��һ���Ѿ��رյ�socket�������ݣ����յ�һ��rst,�����������send�������ٴ�ʹ��recv
		;�Ͳ���һ��socket_error��
		;invoke	send,hNewSocket,addr szRecvBuf,eax,0
	.endw
	invoke	closesocket,hNewSocket
	ret
_NewThread endp

_Main 	proc	uses ebx esi
	LOCAL	wVersionRequested
	LOCAL	wsaData:WSADATA
	LOCAL	sin:sockaddr_in
	LOCAL	ip
	LOCAL	hSocket			;����൱��һ��ר�����������ĵ绰��
	LOCAL	hNewSocket		;���������ͨ���ĵ绰��,��������·
	LOCAL	newSin:sockaddr_in
	LOCAL	newSinLen
	
	;��ʼ��
	mov	wVersionRequested,101h
	invoke	WSAStartup,wVersionRequested,addr wsaData
	.if	eax
		invoke	_WriteConsole,addr szStartErr,0
		ret
	.endif
	
;	invoke	_WriteConsole,addr wsaData.szDescription,0
;	invoke	_WriteEnter
;	invoke	_WriteConsole,addr wsaData.szSystemStatus,0
;	invoke	_WriteEnter
;	movzx	eax,wsaData.iMaxSockets
;	invoke	_WriteInt,eax
;	invoke	_WriteEnter
	
	;����sockaddr_in
	invoke	RtlZeroMemory,addr sin,sizeof sockaddr_in
	mov	sin.sin_family,AF_INET
	mov	sin.sin_addr,INADDR_ANY	;���ʱ�кö�̨�绰
	invoke	htons,9999
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
	
	.while	TRUE
		mov	newSinLen,sizeof newSin
		invoke	RtlZeroMemory,addr newSin,newSinLen
		invoke	accept,hSocket,addr newSin,addr newSinLen
		.if	eax==INVALID_SOCKET
			invoke	_ShowErrCode,addr szAcceptErr
			invoke	closesocket,hSocket
			invoke	WSACleanup
			.break
		.endif
		invoke	CreateThread,0,0,offset _NewThread,eax,0,0
		invoke	CloseHandle,eax
	.endw
	
	invoke	closesocket,hSocket
	invoke	WSACleanup
	ret
_Main endp
start:
	invoke	_InitConsole
	invoke	_Main
	;invoke	_ReadConsole
	invoke	ExitProcess,NULL
end start
