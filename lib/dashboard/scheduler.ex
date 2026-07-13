defmodule Dashboard.Scheduler do
  @moduledoc """
  Quantum-based job scheduler for data collectors.
  """

  use Quantum, otp_app: :dashboard
end
