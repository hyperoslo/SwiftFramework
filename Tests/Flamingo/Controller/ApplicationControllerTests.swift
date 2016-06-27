import XCTest
import PathKit
@testable import Flamingo

class ApplicationControllerTests: XCTestCase {

  static var allTests: [(String, (ApplicationControllerTests) -> () throws -> Void)] {
    return [
      ("testRender", testRender),
      ("testRenderJson", testRenderJson),
      ("testRenderData", testRenderData)
    ]
  }

  let controller = TestResourceController()

  override func setUp() {
    super.setUp()
    Config.viewsDirectory = (Path(#file).parent().parent() + "Fixtures/Views").description
  }

  // MARK: - Tests

  func testRender() {
    let context: [String: Any] = ["title": "Flamingo"]
    let response = controller.render("index", context: context)
    let html = "<!DOCTYPE html>\n<title>Flamingo</title>\n"

    XCTAssertEqual(response.status, Status.ok)
    XCTAssertEqual(response.bodyString, html)
    XCTAssertEqual(
      response.headers["Content-Type"],
      "\(MimeType.html.rawValue); charset=utf8"
    )
  }

  func testRenderJson() {
    let context = JSON.object(["title": "Flamingo", "count": 1])
    let response = controller.render(json: context)
    let string = "{\"count\":1,\"title\":\"Flamingo\"}"

    XCTAssertEqual(response.status, Status.ok)
    XCTAssertEqual(response.bodyString, string)
    XCTAssertEqual(
      response.headers["Content-Type"],
      "\(MimeType.json.rawValue); charset=utf8"
    )
  }

  func testRenderData() {
    let string = "string"
    let response = controller.render(data: string, mime: .text)

    XCTAssertEqual(response.status, Status.ok)
    XCTAssertEqual(response.bodyString, string)
    XCTAssertEqual(
      response.headers["Content-Type"],
      "\(MimeType.text.rawValue); charset=utf8"
    )
  }

  func testRespond() {
    var request = Request(
      method: Method.get,
      uri: URI(path: "/index"),
      body: Data("")
    )

    let context = JSON.object(["title": "Flamingo", "count": 1])
    let string = "{\"count\":1,\"title\":\"Flamingo\"}"

    request.headers["Accept"] = MimeType.json.rawValue

    let response = controller.respond(to: request, [
      .html: { self.controller.render("index") },
      .json: { self.controller.render(json: context) }
    ])

    XCTAssertEqual(response.status, Status.ok)
    XCTAssertEqual(response.bodyString, string)
    XCTAssertEqual(
      response.headers["Content-Type"],
      "\(MimeType.json.rawValue); charset=utf8"
    )
  }

  func testRedirect() {
    let response = controller.redirect(to: "index")

    XCTAssertEqual(response.status, Status.found)
    XCTAssertEqual(response.headers["Location"], "index")
  }
}
