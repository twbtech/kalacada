import os
import pandas as pd

YEAR_OFFSET = 2012
MAX_YEARS = 9
TIME_PERIODS_IN_A_YEAR = int(os.environ['TIME_PERIODS_IN_A_YEAR'])

def prepare_input(data):
    x = data[['year', 'period_number']]

    x['year'] -= YEAR_OFFSET

    for i in range(0, MAX_YEARS):
        x['year_{}'.format(i)] = x.apply(lambda row: (1.0 if row['year'] == i else 0.0), axis=1)

    x['year'] /= float(MAX_YEARS)

    for i in range(1, TIME_PERIODS_IN_A_YEAR + 1):
        x['period_number_{}'.format(i)] = x.apply(lambda row: (1.0 if row['period_number'] == i else 0.0), axis=1)

    x = x.drop(['period_number'], axis=1)

    return x


train_data = pd.read_json(os.environ['HISTORICAL_DATA_PATH'])

from keras.models import Sequential
from keras.layers import Dense, Activation
import keras

x_train = prepare_input(train_data)
y_train = train_data[['value']]

y_coef = float(train_data['value'].max())
y_train['value'] /= y_coef

model = Sequential([
    Dense(32, input_shape=(TIME_PERIODS_IN_A_YEAR + MAX_YEARS + 1,), kernel_initializer='random_uniform', bias_initializer='random_uniform'),
    Activation('tanh'),
    Dense(32, kernel_initializer='random_uniform', bias_initializer='random_uniform'),
    Activation('tanh'),
    Dense(1, kernel_initializer='random_uniform', bias_initializer='random_uniform'),
    Activation('tanh')
])

optimizer = keras.optimizers.RMSprop(lr=0.001)
model.compile(optimizer=optimizer, loss='mse')
model.fit(x_train, y_train, epochs=2000, batch_size=50)

forecast_dates = pd.read_json(os.environ['DATES_TO_FORECAST_PATH'])[['year', 'period_number']]
x_predict      = prepare_input(forecast_dates)

forecast                = model.predict(x_predict)
forecast_dates['value'] = forecast[:,0]
forecast_dates['value'] *= y_coef

forecast_dates.to_json(os.environ['FORECAST_PATH'])
