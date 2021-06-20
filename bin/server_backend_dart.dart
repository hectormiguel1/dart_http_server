import 'dart:collection';
import 'dart:io';
import 'dart:convert';
import 'package:pedantic/pedantic.dart';
import 'participant.dart';


final Directory currentDirectory = Directory.current;
const String fileName = 'participants.json';
const int PORT = 49153;
List<Participant> participants  = [];

void main() async {
  final server = await createServer();
  print('Server Started: ${server.address}: ${server.port}');
  print('Current Directory: ${currentDirectory.path}');

  await loadParticipants();
  print('Loaded participants: ${participants.toString()}' );
  await handleRequests(server);
}

Future<HttpServer> createServer() async {
  final address = InternetAddress.anyIPv4;
  const port = PORT;
  return await HttpServer.bind(address, port);
}

Future<void> handleRequests(HttpServer server) async {
  await for (HttpRequest request in server) {
    try {
      switch (request.method) {
        case 'GET':
          handleGet(request);
          break;
        case 'POST':
          await handlePost(request);
          break;
        case 'PUT':
          await handlePut(request);
          break;
        case 'OPTIONS' :
          handleOptions(request);
          break;
        default:
          {
            print('Unknown Handler for Request: ${request.method}');
            throw Exception;
          }
      }
    } on Exception catch (err) {
      handleExceptions(err, request);
      request.response.statusCode = HttpStatus.internalServerError;
      unawaited(request.response.close());
    }
  }
}
const String AccessControlAllowedMethodsValues = 'GET, POST, PUT';
const String AccessControlAllowedHeaderMethods = 'Access-Control-Allow-Methods';
const String AccessControlAllowedOriginHeader = 'Access-Control-Allow-Origin';
const String AccessControlAllowedOriginValue = '\*';
const String AccessControlAllowHeaders = 'Access-Control-Allow-Headers';
const String AccessControlAllowHeadersValue = '\*';

void handleOptions(HttpRequest request) {
  request.response.headers.add(AccessControlAllowedOriginHeader, AccessControlAllowedOriginValue);
  request.response.headers.add(AccessControlAllowedHeaderMethods, AccessControlAllowedMethodsValues);
  request.response.headers.add(AccessControlAllowHeaders, AccessControlAllowHeadersValue);
  unawaited(request.response.close());
}

void handleGet(HttpRequest request) {
  print('GET HEADER: ${request.headers}');
  //print('GET BODY: ${utf8.decoder.bind(request).join()}');
  var encodedJson = json.encode(participants);
  //print('Encoded participants: $encodedJson');
  request.response.headers.add(AccessControlAllowedOriginHeader, AccessControlAllowedOriginValue);
  request.response.headers.add(AccessControlAllowedHeaderMethods, AccessControlAllowedMethodsValues);
  request.response.statusCode = HttpStatus.ok;
  request.response.write(encodedJson);
  //request.response.flush();
  unawaited(request.response.close());
}

Future<void> handlePost(HttpRequest request) async{
  var body = await utf8.decoder.bind(request).join();
  List<dynamic> requestBody = json.decode(body);
  participants = requestBody.map( (element) => Participant.fromJson(element)).toList();
  print('POST: ${request.headers}');
  unawaited(saveLocal(participants, File(currentDirectory.path + '/' + fileName)).then((_) => print('Files Saved!')));
  request.response.headers.add(AccessControlAllowedOriginHeader, AccessControlAllowedOriginValue);
  request.response.headers.add(AccessControlAllowedHeaderMethods, AccessControlAllowedMethodsValues);
  request.response.headers.add(AccessControlAllowHeaders, AccessControlAllowHeadersValue);

  request.response.statusCode = HttpStatus.ok;
  //await request.response.flush();
  unawaited(request.response.close());
}

Future<void> handlePut(HttpRequest request) async {
  var body = await utf8.decoder.bind(request).join();
  LinkedHashMap<String, dynamic> requestBody = json.decode(body);
  int index = requestBody['index'];
  if(index < participants.length && index > 0) {
    print('Updating ${participants[index]} with ${requestBody['participant']}');
    participants[index] = Participant.fromJson(requestBody['participant']);
    request.response.statusCode = HttpStatus.ok;
    unawaited(saveLocal(participants, File(currentDirectory.path + '/' + fileName)).then((_) => print('Files Saved!')));
  } else {
    request.response.statusCode = HttpStatus.notFound;
   // request.response.write('Index $index not found');
  }
  request.response.headers.add(AccessControlAllowedOriginHeader, AccessControlAllowedOriginValue);
  request.response.headers.add(AccessControlAllowedHeaderMethods, AccessControlAllowedMethodsValues);
  request.response.headers.add(AccessControlAllowHeaders, AccessControlAllowHeadersValue);
  //await request.response.flush();
  unawaited(request.response.close());
}

Future<void> loadParticipants() async {
  var jsonFile = File(currentDirectory.path + '/' + fileName);
  List<dynamic> loadedData = await json.decode(await jsonFile.readAsString());
  participants = loadedData.map( (element) => Participant.fromJson(element)).toList();
}

Future saveLocal(List<Participant> persons, File filePath) async {
  unawaited(filePath.writeAsString(json.encode(
      persons.map((person) => person.toJson()).toList()
  )));
}

void handleExceptions(dynamic err, HttpRequest request) async {
  var body = await utf8.decoder.bind(request).join();
  print('Error Time: ${DateTime.now()}');
  print('Caught Error: ' + err);
  print('On Request: $body');
  print('With Headers: ${request.headers}');
  print('Session: ${request.session}, URI: ${request.uri}');
}


