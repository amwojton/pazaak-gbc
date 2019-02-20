PROJECT_NAME = pazaak

.PHONY: fix

fix: link
	rgbfix -v -p 0 $(PROJECT_NAME).gb

link: assemble
	rgblink -o $(PROJECT_NAME).gb $(PROJECT_NAME).o

assemble: clean
	rgbasm -o $(PROJECT_NAME).o $(PROJECT_NAME).asm

clean:
	del $(PROJECT_NAME).o
