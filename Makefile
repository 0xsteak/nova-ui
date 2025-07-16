.PHONY: convert source bundle rbxm clean

fileName = Nova

all: source bundle rbxm

convert:
	py scripts/convert_source.py rblx_require src rblx-src
source:
	py scripts/build.py source $(fileName).zip
bundle:
	py scripts/build.py bundle $(fileName).luau
rbxm:
	py scripts/build.py rbxm $(fileName).rbxm
clean:
	del /s /q dist\*