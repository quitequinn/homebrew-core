class Ramalama < Formula
  include Language::Python::Virtualenv

  desc "Goal of RamaLama is to make working with AI boring"
  homepage "https://github.com/containers/ramalama"
  url "https://files.pythonhosted.org/packages/f9/8e/2de9843021e00b490a0ab7238da11699341804c1c5b76ae5cd9f980df5de/ramalama-0.12.1.tar.gz"
  sha256 "f372433dc6a9bf0adc01b3f0b252101a44fd13fc19ad0f73b0a5ebdf81d69b10"
  license "MIT"

  bottle do
    rebuild 1
    sha256 cellar: :any_skip_relocation, all: "5bc24164e3be625e6c502044848b355a0885ae7f63af4ac1d33f1eb13aaa253e"
  end

  depends_on "libyaml"
  depends_on "llama.cpp"
  depends_on "python@3.13"

  resource "argcomplete" do
    url "https://files.pythonhosted.org/packages/16/0f/861e168fc813c56a78b35f3c30d91c6757d1fd185af1110f1aec784b35d0/argcomplete-3.6.2.tar.gz"
    sha256 "d0519b1bc867f5f4f4713c41ad0aba73a4a5f007449716b16f385f2166dc6adf"
  end

  resource "pyyaml" do
    url "https://files.pythonhosted.org/packages/54/ed/79a089b6be93607fa5cdaedf301d7dfb23af5f25c398d5ead2525b063e17/pyyaml-6.0.2.tar.gz"
    sha256 "d584d9ec91ad65861cc08d42e834324ef890a082e591037abe114850ff7bbc3e"
  end

  def install
    virtualenv_install_with_resources

    # Build an `:all` bottle by replacing comments
    site_packages = libexec/Language::Python.site_packages("python3")
    inreplace site_packages/"argcomplete-#{resource("argcomplete").version}.dist-info/METADATA",
              "/opt/homebrew/bin/bash",
              "$HOMEBREW_PREFIX/bin/bash"
  end

  test do
    system bin/"ramalama", "pull", "tinyllama"
    list_output = shell_output("#{bin}/ramalama list")
    assert_match "tinyllama", list_output

    inspect_output = shell_output("#{bin}/ramalama inspect tinyllama")
    assert_match "Format: GGUF", inspect_output

    assert_match version.to_s, shell_output("#{bin}/ramalama version")
  end
end
