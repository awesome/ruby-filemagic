require 'test/unit'
require 'filemagic'

class TestFileMagic < Test::Unit::TestCase

  def test_file
    fm = FileMagic.new(FileMagic::MAGIC_NONE)

    res = fm.file(path_to('pyfile'))
    assert_equal('a python script text executable', res)

    if File.symlink?(path_to('pylink'))
      res = fm.file(path_to('pylink'))
      assert_equal("symbolic link to `pyfile'", res)
    end

    fm.close
    fm = FileMagic.new(FileMagic::MAGIC_SYMLINK)

    res = fm.file(path_to('pylink'))
    assert_equal('a python script text executable', res)

    fm.close
    fm = FileMagic.new(FileMagic::MAGIC_SYMLINK | FileMagic::MAGIC_MIME)

    res = fm.file(path_to('pylink'))
    assert_equal('text/plain; charset=us-ascii', res)

    fm.close
    fm = FileMagic.new(FileMagic::MAGIC_COMPRESS)

    res = fm.file(path_to('pyfile-compressed.gz'))
    assert_match(/^a python script text executable \(gzip compressed data, was "pyfile-compressed", from Unix/, res)

    fm.close
  end

  def test_buffer
    fm = FileMagic.new(FileMagic::MAGIC_NONE)
    res = fm.buffer("#!/bin/sh\n")
    fm.close
    assert_match(/shell script text executable$/, res)
  end

  def test_check
    fm = FileMagic.new(FileMagic::MAGIC_NONE)
    res = silence_stderr { fm.check(path_to('perl')) }
    fm.close
    assert_equal(0, res)
  end

  def test_compile
    assert(File.writable?('.'), "can't write to current directory")
    fm = FileMagic.new(FileMagic::MAGIC_NONE)
    res = fm.compile(path_to('perl'))
    fm.close
    assert_equal(0, res)
    File.unlink(path_to('perl.mgc', '.'))
  end

  def test_block
    block_fm = nil
    res = FileMagic.open(FileMagic::MAGIC_NONE) { |fm|
      block_fm = fm
      fm.file(path_to('pyfile'))
    }
    assert_equal('a python script text executable', res)
    assert block_fm.closed?
  end

  def test_setflags
    fm = FileMagic.new(FileMagic::MAGIC_NONE)
    assert_equal([], fm.flags)
    fm.flags = FileMagic::MAGIC_SYMLINK
    assert_equal([:symlink], fm.flags)
    fm.close
  end

  def test_abbr
    fm = FileMagic.new(:mime, :continue)
    assert_equal([:mime_type, :continue, :mime_encoding] , fm.flags)
    fm.flags = :symlink
    assert_equal([:symlink], fm.flags)
    fm.close
  end

  def test_close
    fm = FileMagic.new
    fm.close
    assert fm.closed?
    fm.close
    assert fm.closed?
  end

  # tests adapted from mahoro:

  def test_mahoro_file
    fm = FileMagic.new
    fm.flags = FileMagic::MAGIC_NONE
    assert_equal('ASCII C program text', fm.file(path_to('mahoro.c')))
  end

  def test_mahoro_mime_file
    fm = FileMagic.new
    fm.flags = FileMagic::MAGIC_MIME
    assert_equal('text/x-c; charset=us-ascii', fm.file(path_to('mahoro.c')))
  end

  def test_mahoro_buffer
    fm = FileMagic.new
    fm.flags = FileMagic::MAGIC_NONE
    assert_equal('ASCII C program text', fm.buffer(File.read(path_to('mahoro.c'))))
  end

  def test_mahoro_mime_buffer
    fm = FileMagic.new
    fm.flags = FileMagic::MAGIC_MIME
    assert_equal('text/x-c; charset=us-ascii', fm.buffer(File.read(path_to('mahoro.c'))))
  end

  def test_mahoro_valid
    fm = FileMagic.new
    assert(silence_stderr { fm.valid? }, 'Default database was not valid.')
  end

  # test abbreviating mime types

  def test_abbrev_mime_type
    fm = FileMagic.mime

    assert !fm.simplified?
    assert_equal('text/plain; charset=us-ascii', fm.file(path_to('perl')))

    fm.simplified = true
    assert fm.simplified?
    assert_equal('text/plain', fm.file(path_to('perl')))
    assert_equal('application/vnd.ms-office', fm.file(path_to('excel-example.xls')))
  end

  # utility methods:

  def path_to(file, dir = File.dirname(__FILE__))
    File.join(dir, file)
  end

  def silence_stderr
    require 'nuggets/io/redirect'
    $stderr.redirect { yield }
  rescue LoadError
    yield
  end

end
