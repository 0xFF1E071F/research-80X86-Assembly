assume cs:code
data segment
	db 8,11,8,1,8,5,63,38
data ends
code segment
start:
	mov ax,data
	mov ds,ax

	mov cx,8
	mov si,0
	mov ax,0
checkA8:
	cmp byte ptr ds:[si],8
	jna na8
	inc ax
na8:
	inc si
	loop checkA8
	
	mov ax,4c00h
	int 21h
code ends
end start