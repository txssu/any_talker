defmodule JokerCynic.Antispam.KickUserJob do
  @moduledoc false
  use Oban.Worker, queue: :default

  alias JokerCynic.Antispam

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"captcha_id" => captcha_id}}) do
    # Check if captcha is still relevant
    captcha = Antispam.get_captcha(captcha_id)

    if not is_nil(captcha) and captcha.status == :created do
      Antispam.time_out_captcha(captcha)
    end

    :ok
  end
end
