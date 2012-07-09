all:
	@make -s --no-print-directory -C ../.. clean all rpm
	@basedir=../.. testdir=../ ./test.sh --all
setup:
	@make --no-print-directory -C ../.. clean rpm
	@basedir=../.. testdir=../ ./test.sh --setup
clean:
	@basedir=../.. testdir=../ ./test.sh --clean
run:
	@basedir=../.. testdir=../ ./test.sh --run
