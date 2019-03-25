task generate_forecast: :environment do
  Forecasting::Generator.generate
end
