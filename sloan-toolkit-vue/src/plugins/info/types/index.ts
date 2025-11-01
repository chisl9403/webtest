export interface WeatherData {
  name: string
  temp: number
  description: string
  icon: string
  humidity: number
  windSpeed: number
  feelsLike: number
  pressure: number
}

export interface WeatherConfig {
  enabled: boolean
  autoLoad: boolean
  defaultCity: string
  apiKey: string
}
