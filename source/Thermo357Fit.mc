import Toybox.Lang;
using Toybox.FitContributor as Fit;

// see https://github.com/garmin/connectiq-apps for reference on FitContributor

const TEMPERATURE_FIELD_RECORD_ID = 0;
const TEMPERATURE_NATIVE_NUM_RECORD_MESG = 3;

/*
const TEMPERATURE_FIELD_SESSION_MIN_ID = 1;
const TEMPERATURE_FIELD_SESSION_MAX_ID = 2;
const TEMPERATURE_FIELD_SESSION_AVG_ID = 3;
const TEMPERATURE_FIELD_LAP_MIN_ID = 4;
const TEMPERATURE_FIELD_LAP_MAX_ID = 5;
const TEMPERATURE_FIELD_LAP_AVG_ID = 6;


const TEMPERATURE_NATIVE_NUM_SESSION_MIN_MESG = 64;
const TEMPERATURE_NATIVE_NUM_SESSION_MAX_MESG = 17;
const TEMPERATURE_NATIVE_NUM_SESSION_AVG_MESG = 16;

const TEMPERATURE_NATIVE_NUM_LAP_MIN_MESG = 63;
const TEMPERATURE_NATIVE_NUM_LAP_MAX_MESG = 16;
const TEMPERATURE_NATIVE_NUM_LAP_AVG_MESG = 15;
*/
const TEMPERATURE_UNITS = "°C";

class Thermo357Fit {

    protected var mTemperatureRecordField;
    /*protected var mMinTemperatureSessionField;
    protected var mMaxTemperatureSessionField;
    protected var mAvgTemperatureSessionField;
    protected var mMinTemperatureLapField;
    protected var mMaxTemperatureLapField;
    protected var mAvgTemperatureLapField;*/
    
	protected var mTimerRunning = false;
	protected var mSessionStats;
	protected var mLapStats;

    function initialize(dataField) {

       
        mTemperatureRecordField = dataField.createField("temperature", 
          TEMPERATURE_FIELD_RECORD_ID, Fit.DATA_TYPE_FLOAT, 
          { :nativeNum=>TEMPERATURE_NATIVE_NUM_RECORD_MESG, :mesgType=>Fit.MESG_TYPE_RECORD, :units=>TEMPERATURE_UNITS });
        
        /*
        mMinTemperatureSessionField = dataField.createField("min_temperature", TEMPERATURE_FIELD_SESSION_MIN_ID, Fit.DATA_TYPE_UINT8, { :nativeNum=>TEMPERATURE_NATIVE_NUM_SESSION_MIN_MESG, :mesgType=>Fit.MESG_TYPE_SESSION, :units=>TEMPERATURE_UNITS });
        mMaxTemperatureSessionField = dataField.createField("max_temperature", TEMPERATURE_FIELD_SESSION_MAX_ID, Fit.DATA_TYPE_UINT8, { :nativeNum=>TEMPERATURE_NATIVE_NUM_SESSION_MAX_MESG, :mesgType=>Fit.MESG_TYPE_SESSION, :units=>TEMPERATURE_UNITS });
        mAvgTemperatureSessionField = dataField.createField("avg_temperature", TEMPERATURE_FIELD_SESSION_AVG_ID, Fit.DATA_TYPE_UINT8, { :nativeNum=>TEMPERATURE_NATIVE_NUM_SESSION_AVG_MESG, :mesgType=>Fit.MESG_TYPE_SESSION, :units=>TEMPERATURE_UNITS });
        
        mMinTemperatureLapField = dataField.createField("min_temperature", TEMPERATURE_FIELD_LAP_MIN_ID, Fit.DATA_TYPE_UINT8, { :nativeNum=>TEMPERATURE_NATIVE_NUM_LAP_MIN_MESG, :mesgType=>Fit.MESG_TYPE_LAP, :units=>TEMPERATURE_UNITS });
        mMaxTemperatureLapField = dataField.createField("max_temperature", TEMPERATURE_FIELD_LAP_MAX_ID, Fit.DATA_TYPE_UINT8, { :nativeNum=>TEMPERATURE_NATIVE_NUM_LAP_MAX_MESG, :mesgType=>Fit.MESG_TYPE_LAP, :units=>TEMPERATURE_UNITS });
        mAvgTemperatureLapField = dataField.createField("avg_temperature", TEMPERATURE_FIELD_LAP_AVG_ID, Fit.DATA_TYPE_UINT8, { :nativeNum=>TEMPERATURE_NATIVE_NUM_LAP_AVG_MESG, :mesgType=>Fit.MESG_TYPE_LAP, :units=>TEMPERATURE_UNITS });

		mSessionStats = new MinMaxAvg(false);
		mLapStats = new MinMaxAvg(false);
        */
    }


    function setTemperatureData(temp10) {
        debug_prt("Thermo357Fit.setTemperatureData: " + temp10/10.0 + " °C", null);
    	mTemperatureRecordField.setData(temp10/10.0);
    	
        /*
    	if(mTimerRunning) {
    		mSessionStats.setData(heartrate);
    		mLapStats.setData(heartrate);
    		
			mMinTemperatureSessionField.setData(mSessionStats.min());
			mMaxTemperatureSessionField.setData(mSessionStats.max());
			mAvgTemperatureSessionField.setData(mSessionStats.avg());
			
			mMinTemperatureLapField.setData(mSessionStats.min());
			mMaxTemperatureLapField.setData(mSessionStats.max());
			mAvgTemperatureLapField.setData(mSessionStats.avg());
    	}
        */
    }
    function onNextMultisportLeg() {
    	mSessionStats.reset();
    	mLapStats.reset();
    }

    function onTimerLap() {
    	mLapStats.reset();
    }
    
    function onTimerReset() {
    	mSessionStats.reset();
    	mLapStats.reset();
    }
    
    function onTimerPause() {
    	mTimerRunning = false;
    }
    
    function onTimerResume() {
        mTimerRunning = true;
    }
    
    function onTimerStart() {
        mTimerRunning = true;
    }

    function onTimerStop() {
        mTimerRunning = false;
    }

}