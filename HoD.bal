import ballerina/http;
import ballerina/io;
import ballerina/log;
import ballerina/uuid;
import ballerinax/kafka;

isolated function getDataStore() returns string {
    return "./files/DataStorage.json";
}

service /HoD on new http:Listener(9080) {
    resource function get viewCourseOutlines(http:Caller caller) returns error? {
        http:Response response = new ();

        json readJson = check io:fileReadJson(getDataStore());

        response.setJsonPayload(readJson);

        var result = caller->respond(response);
        if (result is error) {
            log:printError("Error sending response", result);
        }
    }

    resource function put approveCourseOutline(http:Caller caller, string Id) returns error? {
        http:Response response = new ();

        if (Id == "") {
            response.setJsonPayload({"Message": "Invalid payload - Id or approave code"});
            var result = caller->respond(response);
            if (result is error) {
                log:printError("Error sending response", result);
            }
        } else {
            map<json> courseOutlineMap = {};
            json readJson = check io:fileReadJson(getDataStore());

            courseOutlineMap = <map<json>>readJson;
            map<json> existingcourseOutline = <map<json>>courseOutlineMap[Id];
            existingcourseOutline["IsApprovedByHoD"] = true;

            courseOutlineMap[Id] = existingcourseOutline;

            check io:fileWriteJson(getDataStore(), courseOutlineMap);

            //start send message to kafka
            kafka:Producer kafkaProducer = check new (kafka:DEFAULT_URL);
            check kafkaProducer->send({
                                topic: "courseOutline",
                                value: existingcourseOutline.toString().toBytes()});

            check kafkaProducer->'flush();
            //start send message to kafka

            json payload = {status: "Course Outline approaved by HoD"};
            response.setJsonPayload(payload);
            var result = caller->respond(response);
            if (result is error) {
                log:printError("Error sending response", result);
            }
        }
    }

    resource function put updateCourseOutline(http:Caller caller, http:Request request, string Id) returns error? {
        http:Response response = new ();
        var updatedcourseOutline = request.getJsonPayload();
        if (updatedcourseOutline is json) {
            map<json> courseOutlineMap = {};
            json readJson = check io:fileReadJson(getDataStore());

            courseOutlineMap = <map<json>>readJson;

            json existingcourseOutline = courseOutlineMap[Id];

            if (existingcourseOutline != null) {

                courseOutlineMap[Id] = updatedcourseOutline;

                check io:fileWriteJson(getDataStore(), courseOutlineMap);

                json payload = {status: "Course Outline successfully updated"};
                response.setJsonPayload(payload);
                var result = caller->respond(response);
                if (result is error) {
                    log:printError("Error sending response", result);
                }
            } else {
                response.setPayload("Invalid payload received");
                var result = caller->respond(response);
                if (result is error) {
                    log:printError("Error sending response", result);
                }
            }

        }
    }

    resource function post createCourseOutline(http:Caller caller, http:Request request) returns error? {
        http:Response response = new ();
        var courseOutlineReq = request.getJsonPayload();

        if (courseOutlineReq is json) {
            map<json> courseOutlineMap = {};
            string Id = uuid:createType1AsString();

            json readJson = check io:fileReadJson(getDataStore());

            if (readJson != null) {
                courseOutlineMap = <map<json>>readJson;
            }

            courseOutlineMap[Id] = courseOutlineReq;

            check io:fileWriteJson(getDataStore(), courseOutlineMap);

            json payload = {status: "Course Outline Created.", Id: Id};
            response.setJsonPayload(payload);

            var result = caller->respond(response);
            if (result is error) {
                log:printError("Error sending response", result);
            }
        } else {
            response.setPayload("Invalid payload received");
            var result = caller->respond(response);
            if (result is error) {
                log:printError("Error sending response", result);
            }
        }

    }

}
