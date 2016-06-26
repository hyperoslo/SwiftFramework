/**
  Main application controller every controller must conform to.
*/
public protocol ApplicationController {
  init()
}

// MARK: - Rendering

public extension ApplicationController {

  /**
    Renders a view template using a renderer from the config.

    - Parameter template: The name of a template.
    - Parameter context: Context parameters to use in a template.
    - Returns: A response.
  */
  public func render(_ template: String, context: [String: Any] = [:]) -> Response {
    let body = Config.ViewRenderer.init(path: template, context: context).render()
    return Response(status: .ok, contentType: .html, body: body)
  }

  public func render(json: JSONRepresentable) -> Response {
    return Response(status: .ok, contentType: .json, body: json.json)
  }
}

/**
  Controller that is aware of adding new routes.
*/
public protocol RoutingController: ApplicationController {

  /**
    Method to register routes.

    - Parameter map: Route container.
  */
  func draw(map: RouteContainer)
}
