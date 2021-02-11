defmodule OS do
  def home() do
    {:ok, [[home]]} = :init.get_argument(:home)
    List.to_string(home)
  end

  def raise_frame(frame) do
    if type() == MacOS do
      name = System.get_env("EMU", "beam.smp")

      fn -> System.cmd("open", ["-a", name], stderr_to_stdout: true) end
      |> spawn_link()
    else
      # Calling  this on wxDirDialog segfaults on macos..
      :wxTopLevelWindow.setFocus(frame)
      :wxWindow.raise(frame)
    end
  end

  def type() do
    case :os.type() do
      {:unix, :darwin} -> MacOS
      {:unix, :linux} -> Linux
      {:win32, _} -> Windows
    end
  end

  def shutdown() do
    spawn(fn ->
      Process.sleep(300)
      kill_heart()
      System.halt(0)
    end)
  end

  def windows?() do
    type() == Windows
  end

  defp kill_heart() do
    heart = Process.whereis(:heart)

    if heart != nil do
      {:links, links} = Process.info(Process.whereis(:heart), :links)
      port = Enum.find(links, fn id -> is_port(id) end)

      if port != nil do
        {:os_pid, heart_pid} = Port.info(port, :os_pid)
        System.cmd("kill", ["-9", "#{heart_pid}"], stderr_to_stdout: true)
        # kill thyself
        kill_beam()
      end
    end
  end

  defp kill_beam() do
    System.cmd("kill", ["-9", "#{:os.getpid()}"], stderr_to_stdout: true)
  end

  # This is a Path.expand variant that normalizes the drive letter
  # on windows
  def path_expand(path) do
    if windows?() do
      path = Path.expand(path)
      drv = String.first(path)
      String.replace_prefix(path, drv <> ":", String.upcase(drv) <> ":")
    else
      Path.expand(path)
    end
  end

  def invert_menu(menulist) do
    # Windows has the menu at the bottom
    if windows?() do
      Enum.reverse(menulist)
      # Linux and macOS have the menu at the top by default
    else
      menulist
    end
  end
end
