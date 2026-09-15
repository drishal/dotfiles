{
  config,
  inputs,
  pkgs,
  ...
}:
{
  # layout borrowed from FullFran/fulfran-dots; theme stays stylix
  programs.btop = {
    enable = true;
    settings = {
      # HM owns btop.conf (store symlink); btop writing it on exit fails read-only
      save_config_on_exit = false;
      # no darkening fade-down in the process list
      proc_gradient = false;

      presets = "cpu:1:braille,gpu0:0:braille,proc:0:braille cpu:0:braille,mem:0:block,gpu0:0:braille,net:0:braille cpu:0:block,mem:0:block,gpu0:0:braille,net:0:tty,proc:1:braille";
      shown_boxes = "cpu mem gpu0 net proc";
      graph_symbol = "braille";
      graph_symbol_cpu = "braille";
      graph_symbol_gpu = "braille";
      graph_symbol_mem = "block";
      graph_symbol_net = "braille";
      graph_symbol_proc = "braille";
      update_ms = 1000;
      vim_keys = true;
      clock_format = "";
      cpu_graph_upper = "total";
      cpu_graph_lower = "total";
      freq_mode = "average";
      nvml_measure_pcie_speeds = false;
      rsmi_measure_pcie_speeds = false;
    };
  };
}
