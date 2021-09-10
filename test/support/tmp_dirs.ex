defmodule Support.TmpDirs do
  def root do
    File.cwd!()
  end

  def tmp_path do
    Path.expand("tmp", root())
  end

  defp random_string(len) do
    len |> :crypto.strong_rand_bytes() |> Base.encode64() |> binary_part(0, len)
  end

  def in_tmp(which, function) do
    tmp = Path.join([tmp_path(), random_string(10)])
    path = Path.join([tmp, to_string(which)])

    try do
      File.rm_rf!(path)
      File.mkdir_p!(path)
      File.cd!(path, function)
    after
      File.rm_rf!(tmp)
    end
  end
end
