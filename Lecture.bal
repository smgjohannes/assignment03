import ballerina/http;
import ballerina/io;
import ballerina/log;
import ballerina/uuid;

isolated function getDataStore() returns string {
    return "./files/DataStorage.json";
}

service /Leacture on new http:Listener(9081) {
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

    resource function get viewCourseOutlines(http:Caller caller, string Id) returns error? {
        http:Response response = new ();

        json readJson = check io:fileReadJson(getDataStore());

        map<json> courseOutlineMap = <map<json>>readJson;
        json? payload = courseOutlineMap[Id];

        if (payload == null) {
            payload = "Course outline : " + Id + " cannot be found.";
        }

        response.setJsonPayload(readJson);

        var result = caller->respond(response);
        if (result is error) {
            log:printError("Error sending response", result);
        }

    }

    resource function put signCourseOutline(http:Caller caller, string Id) returns error? {
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
            existingcourseOutline["IsSignedByLeacture"] = true;

            courseOutlineMap[Id] = existingcourseOutline;

            check io:fileWriteJson(getDataStore(), courseOutlineMap);

            json payload = {status: "Course Outline signed by Lecture"};

            response.setJsonPayload(payload);
            var result = caller->respond(response);
            if (result is error) {
                log:printError("Error sending response", result);
            }
        }
    }

}
