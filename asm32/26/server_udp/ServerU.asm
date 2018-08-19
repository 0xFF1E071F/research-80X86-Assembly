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
szRecvBuf	db	1024  dup(?)
		.const
szIP		db	'127.0.0.1',0
szStartErr	db	'Init Socket Err',0dh,0ah,0
szAddrErr	db	'inet_addr Err',0dh,0ah,0
szErrCode	db	'%s errorCode is %d',0
szSockErr	db	'socket',0
szBindErr	db	'bind',0
szListenErr	db	'listen',0
szAcceptErr	db	'accept',0
szRecvErr	db	'recv',0
;����
.code

_ShowErrCode proc lpTypeStr
	invoke	WSAGetLastError
	invoke	wsprintf,addr szErrBuf,addr szErrCode,lpTypeStr,eax
	invoke	_WriteConsole,addr szErrBuf,0
	invoke	_WriteEnter
	ret
_ShowErrCode endp

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
	mov	wVersionRequested,202h
	invoke	WSAStartup,wVersionRequested,addr wsaData
	.if	eax
		invoke	_WriteConsole,addr szStartErr,0
		ret
	.endif
	
	invoke	_WriteConsole,addr wsaData.szDescription,0
	invoke	_WriteEnter
	invoke	_WriteConsole,addr wsaData.szSystemStatus,0
	invoke	_WriteEnter
	movzx	eax,wsaData.iMaxSockets
	invoke	_WriteInt,eax
	invoke	_WriteEnter
	
	;����sockaddr_in
	invoke	RtlZeroMemory,addr sin,sizeof sockaddr_in
	mov	sin.sin_family,AF_INET
	mov	sin.sin_addr,INADDR_ANY	;���ʱ�кö�̨�绰
	invoke	htons,5150
	mov	sin.sin_port,ax
	
	;�׽��֣�����ͨ�ŵĶ���,������Ϊͨ�ŵ�һ��,����һ�˱�������һ���׽��֣����ܽ���ͨ��
	;�׽��ַ�Ϊ���֣����׽��֣����ݱ��׽���
	invoke	socket,AF_INET,SOCK_DGRAM,0
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
	
	mov	newSinLen,sizeof newSin
	invoke	RtlZeroMemory,addr newSin,newSinLen
	
	;ʹ��UDPҪע��socket�����ͣ�һ��Ҫ��SOCK_DGRAM������ᱨ10057�Ĵ�
	;���ջ�������������󣬻ᱨ10040�Ĵ�
	.while	TRUE
		invoke	recvfrom,hSocket,addr szRecvBuf,sizeof szRecvBuf,0,addr newSin,addr newSinLen
		.if	eax==SOCKET_ERROR
			invoke	WSAGetLastError
			.if	eax!=WSAEWOULDBLOCK
				invoke	_ShowErrCode,addr szRecvErr
				.break
			.endif
			.continue
		.endif
		invoke	_WriteConsole,addr szRecvBuf,0
		.break
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
