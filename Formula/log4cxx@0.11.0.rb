class Log4cxxAT0110 < Formula
  desc "Library of C++ classes for flexible logging"
  homepage "https://logging.apache.org/log4cxx/index.html"
  url "https://www.apache.org/dyn/closer.lua?path=logging/log4cxx/0.11.0/apache-log4cxx-0.11.0.tar.gz"
  mirror "https://archive.apache.org/dist/logging/log4cxx/0.11.0/apache-log4cxx-0.11.0.tar.gz"
  sha256 "c316705ee3c4e5b919d3561d5f305162d21687aa6ae1f31f02f6cdadc958b393"
  license "Apache-2.0"

  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "libtool" => :build

  depends_on "apr-util"

  def install
    # Fixes build error with clang, old libtool scripts. cf. #12127
    # Reported upstream here: https://issues.apache.org/jira/browse/LOGCXX-396
    # Remove at: unknown, waiting for developer comments.
    system "./autogen.sh"
    system "./configure", "--disable-debug", "--disable-dependency-tracking",
                          "--prefix=#{prefix}",
                          # Docs won't install on macOS
                          "--disable-doxygen",
                          "--with-apr=#{Formula["apr"].opt_bin}",
                          "--with-apr-util=#{Formula["apr-util"].opt_bin}"
    system "make", "install"
  end

  test do
    (testpath/"test.cpp").write <<~EOS
      #include <log4cxx/logger.h>
      #include <log4cxx/propertyconfigurator.h>
      int main() {
        log4cxx::PropertyConfigurator::configure("log4cxx.config");
        log4cxx::LoggerPtr log = log4cxx::Logger::getLogger("Test");
        log->setLevel(log4cxx::Level::getInfo());
        LOG4CXX_ERROR(log, "Foo");
        return 1;
      }
    EOS
    (testpath/"log4cxx.config").write <<~EOS
      log4j.rootLogger=debug, stdout, R
      log4j.appender.stdout=org.apache.log4j.ConsoleAppender
      log4j.appender.stdout.layout=org.apache.log4j.PatternLayout
      # Pattern to output the caller's file name and line number.
      log4j.appender.stdout.layout.ConversionPattern=%5p [%t] (%F:%L) - %m%n
      log4j.appender.R=org.apache.log4j.RollingFileAppender
      log4j.appender.R.File=example.log
      log4j.appender.R.MaxFileSize=100KB
      # Keep one backup file
      log4j.appender.R.MaxBackupIndex=1
      log4j.appender.R.layout=org.apache.log4j.PatternLayout
      log4j.appender.R.layout.ConversionPattern=%p %t %c - %m%n
    EOS
    system ENV.cxx, "test.cpp", "-o", "test", "-L#{lib}", "-llog4cxx"
    assert_match(/ERROR.*Foo/, shell_output("./test", 1))
  end
end
