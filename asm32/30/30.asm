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
testInt		dd 1024
;testInt1:	dd 2048	masm32�Ѿ�����������д����
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
;�����
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
.code
func	proc
	local	arr[256]:dword
	mov		eax,testInt
	lea		eax,testInt
	mov		eax,arr
	mov		eax,arr[1]
	lea		eax,arr
	ret
func	endp
start:
	invoke	func
	invoke	ExitProcess,NULL
end start