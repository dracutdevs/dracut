all:
	make -C ../.. all
	@basedir=../.. testdir=../ ./test.sh --all
setup:
	make -C ../.. all
	@basedir=../.. testdir=../ ./test.sh --setup
clean:
	@basedir=../.. testdir=../ ./test.sh --clean
run:
	@basedir=../.. testdir=../ ./test.sh --run
