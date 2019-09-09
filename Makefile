PROJECT_NAME = pazaak

.PHONY: clean

clean: fix
	del $(PROJECT_NAME).o

fix: link
	rgbfix -v -p 0 $(PROJECT_NAME).gb

link: assemble
	rgblink -o $(PROJECT_NAME).gb $(PROJECT_NAME).o

assemble: 
	rgbasm -o $(PROJECT_NAME).o $(PROJECT_NAME).asm
