CREATE PROCEDURE [dbo].[PredictTipSingleModeRxPy] (@model varchar(50), @passenger_count int = 0,
@trip_distance float = 0,
@trip_time_in_secs int = 0,
@pickup_latitude float = 0,
@pickup_longitude float = 0,
@dropoff_latitude float = 0,
@dropoff_longitude float = 0)
AS
BEGIN
	DECLARE @inquery nvarchar(max) = N'
	SELECT * FROM [dbo].[fnEngineerFeatures]( 
	@passenger_count,
	@trip_distance,
	@trip_time_in_secs,
	@pickup_latitude,
	@pickup_longitude,
	@dropoff_latitude,
	@dropoff_longitude)
	'
	DECLARE @lmodel2 varbinary(max) = (select model from nyc_taxi_models2 where name = @model);
	EXEC sp_execute_external_script 
		@language = N'Python',
		@script = N'
import pickle;
import numpy;
import pandas;
from revoscalepy.functions.RxPredict import rx_predict_ex;

# Load model and unserialize
mod = pickle.loads(model)

# Get features for scoring from input data
X = InputDataSet[["passenger_count", "trip_distance", "trip_time_in_secs", "direct_distance"]]

# Score data to get tip prediction probability as a list (of float)

probArray = rx_predict_ex(mod, X)

probList = []
probList.append(probArray._results["tipped_Pred"])

# Create output data frame
OutputDataSet = pandas.DataFrame(data = probList, columns = ["predictions"])
	',
	@input_data_1 = @inquery,
	@params = N'@model varbinary(max),@passenger_count int,@trip_distance float,
		@trip_time_in_secs int ,
		@pickup_latitude float ,
		@pickup_longitude float ,
		@dropoff_latitude float ,
		@dropoff_longitude float',
	@model = @lmodel2,
		@passenger_count =@passenger_count ,
		@trip_distance=@trip_distance,
		@trip_time_in_secs=@trip_time_in_secs,
		@pickup_latitude=@pickup_latitude,
		@pickup_longitude=@pickup_longitude,
		@dropoff_latitude=@dropoff_latitude,
		@dropoff_longitude=@dropoff_longitude
	WITH RESULT SETS ((Score float));
END
GO
