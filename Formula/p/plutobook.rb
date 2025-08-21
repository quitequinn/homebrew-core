class Plutobook < Formula
  desc "Paged HTML Rendering Library"
  homepage "https://github.com/plutoprint/plutobook"
  url "https://github.com/plutoprint/plutobook/archive/refs/tags/v0.5.0.tar.gz"
  sha256 "7a23622797a911a86fe28a9e69b38243aa362e235be70a8138cbed40bdb96a96"
  license "MIT"

  depends_on "meson" => :build
  depends_on "ninja" => :build
  depends_on "pkgconf" => :build
  depends_on "cairo"
  depends_on "fontconfig"
  depends_on "freetype"
  depends_on "harfbuzz"
  depends_on "icu4c@77"
  depends_on "jpeg-turbo"
  depends_on "libidn2"
  depends_on "webp"
  uses_from_macos "curl"
  uses_from_macos "expat"

  on_macos do
    depends_on "llvm" if DevelopmentTools.clang_build_version <= 1500
  end

  on_ventura do
    depends_on "llvm"
  end

  fails_with :clang do
    build 1500
    cause "Requires C++20 support"
  end

  def install
    if OS.mac? && (MacOS.version == :ventura || DevelopmentTools.clang_build_version <= 1500)
      # Use Homebrew LLVM toolchain and its libc++ consistently to avoid ABI mismatches
      ENV.llvm_clang
      llvm = Formula["llvm"]
      # Ensure we pick up LLVM's libc++ headers when using its toolchain
      ENV.append "CPPFLAGS", "-I#{llvm.opt_include}/c++/v1"
      # Link against LLVM's libc++, libc++abi and libunwind, and embed rpaths so the loader can find them
      ENV.append "LDFLAGS", "-L#{llvm.opt_lib}/c++ -L#{llvm.opt_lib} -L#{llvm.opt_lib}/unwind"
      ENV.append "LDFLAGS", "-Wl,-rpath,#{llvm.opt_lib}/c++ -Wl,-rpath,#{llvm.opt_lib}"
      ENV.append "LDFLAGS", "-lc++ -lc++abi -lunwind"
      # Use libc++ (required by LLVM toolchain on macOS)
      ENV.append "CXXFLAGS", "-stdlib=libc++"
    end

    system "meson", "setup", "build", *std_meson_args
    system "meson", "compile", "-C", "build", "--verbose"
    system "meson", "install", "-C", "build"
  end

  test do
    (testpath/"test.cpp").write <<~EOS
      #include <plutobook/plutobook.hpp>

      static const char kHTMLContent[] = R"HTML(
      <!DOCTYPE html>
      <html>
      <body>Hello!</body>
      </html>
      )HTML";

      int main() {
        plutobook::Book book(plutobook::PageSize::A4, plutobook::PageMargins::Narrow);
        book.loadHtml(kHTMLContent);
        book.writeToPdf("test.pdf");
        return 0;
      }
    EOS
    system ENV.cxx, "test.cpp", "-std=c++20", "-I#{include}", "-L#{lib}", "-lplutobook", "-o", "test"
    system "./test"
    assert_path_exists testpath/"test.pdf"
  end
end
