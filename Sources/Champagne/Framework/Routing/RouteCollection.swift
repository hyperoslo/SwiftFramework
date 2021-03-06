/**
  Route container keeps and builds routes relative to the root path.
*/
public class RouteCollection: RouteGetBuilding, RoutePostBuilding,
  RoutePutBuilding, RoutePatchBuilding, RouteDeleteBuilding, RouteOptionsBuilding {

  /// Root path.
  public let path: String

  /// List of registerd routes.
  public var routes: [Route] = []

  /// Append leading slash to the route path
  public var appendLeadingSlash = true

  /// Append trailing slash to the route path
  public var appendTrailingSlash = false

  /**
    Creates a new `RouteCollection` instance.

    - Parameter path: The root path..
  */
  public init(path: String = "") {
    self.path = path
  }

  /**
    Builds a route and adds responder as an action on the corresponding method.

    - Parameter method: The request method.
    - Parameter path: Route path.
    - Parameter middleware: Route-specific middleware.
    - Parameter responder: The responder.
  */
  public func add(method: Method, path: String, middleware: [Middleware], responder: Responder) {
    let action = middleware.chain(to: responder)
    let path = absolutePathFor(path)

    if let route = routeFor(absolutePath: path) {
      route.addAction(method: method, action: action)
    } else {
      let route = Route(path: path, actions: [method: action])
      routes.append(route)
    }
  }

  /**
    Adds a fallback on a given path.

    - Parameter path: Route path.
    - Parameter middleware: Route-specific middleware.
    - Parameter responder: The responder.
  */
  public func fallback(on path: String, middleware: [Middleware], responder: Responder) {
    let fallback = middleware.chain(to: responder)
    let path = absolutePathFor(path)

    if let route = routeFor(absolutePath: path) {
      route.fallback = fallback
    } else {
      let route = Route(path: path, fallback: fallback)
      routes.append(route)
    }
  }

  /**
    Removes all routes
  */
  public func clear() {
    routes.removeAll()
  }
}

// MARK: - Fallbacks

public extension RouteCollection {

  /**
    Adds a fallback on a given path.

    - Parameter path: Route path.
    - Parameter middleware: Route-specific middleware.
    - Parameter respond: The responder.
  */
  func fallback(_ path: String = "", middleware: [Middleware] = [], respond: Respond) {
    fallback(on: path, middleware: middleware, responder: BasicResponder(respond))
  }

  /**
    Adds a fallback on a given path.

    - Parameter path: Route path.
    - Parameter middleware: Route-specific middleware.
    - Parameter responder: The responder.
  */
  func fallback(_ path: String = "", middleware: [Middleware] = [], responder: Responder) {
    fallback(on: path, middleware: middleware, responder: responder)
  }
}

// MARK: - Root

public extension RouteCollection {

  /**
    Adds a responder on the root path (`GET /`).

    - Parameter middleware: Route-specific middleware.
    - Parameter responder: The responder.
  */
  func root(middleware: [Middleware] = [], responder: Responder) {
    get("", middleware: middleware, responder: responder)
  }

  /**
    Adds a responder on the root path (`GET /`).

    - Parameter middleware: Route-specific middleware.
    - Parameter respond: The responder.
  */
  func root(middleware: [Middleware] = [], respond: Respond) {
    get("", middleware: middleware, responder: BasicResponder(respond))
  }
}

// MARK: - Namespace

public extension RouteCollection {

  /**
    Builds a set of routes scoped by the given path.
    Allows to create nested route structures.

    - Parameter path: Namespace path.
    - Parameter middleware: Route-specific middleware.
    - Parameter build: Closure to fill in a new container with routes.
  */
  func namespace(_ path: String,
                   middleware: [Middleware] = [],
                   build: (container: RouteCollection) -> Void) {
    let container = RouteCollection(path: path)

    build(container: container)

    for route in container.routes {
      for (method, action) in route.actions {
        add(method: method,
          path: route.path,
          middleware: middleware,
          responder: action
        )
      }

      fallback(route.path, responder: route.fallback)
    }
  }

  /**
    Uses routing controller on specified path.

    - Parameter path: Path associated with resource controller.
    - Parameter middleware: Route-specific middleware.
    - Parameter factory: Closure to instantiate a new instance of controller.
  */
  func namespace<T: RouteMapper>(_ path: String,
                             middleware: [Middleware] = [],
                                factory: () -> T) {
    let builder = factory()
    namespace(path, middleware: middleware, build: builder.draw)
  }
}

// MARK: - Resources

extension RouteCollection {

  /**
    Creates standard Index, New, Show, Edit, Create, Destroy and Update routes
    using the respond method from a supplied `ResourceResponseFactory`.

    - Parameter path: Path associated with resource controller.
    - Parameter middleware: Route-specific middleware.
    - Parameter only: Included CRUD actions.
    - Parameter except: Excluded CRUD actions.
    - Parameter factory: Closure to instantiate a new instance of controller.
  */
  public func resources<T: ResourceResponseFactory>(_ path: String,
                                                middleware: [Middleware] = [],
                                                      only: [ResourceAction]? = nil,
                                                    except: [ResourceAction]? = nil,
                                                   factory: () -> T) {
    var actions: [ResourceAction] = [
      .index, .new, .show, .edit,
      .create, .destroy, .update
    ]

    if let only = only {
      actions = only
    }

    if let except = except {
      actions = actions.filter({ !except.contains($0) })
    }

    for action in actions {
      addResourceAction(action, on: path, middleware: middleware, factory: factory)
    }
  }

  /**
    Creates standard Index, New, Show, Edit, Create, Destroy and Update routes
    using the respond method from a supplied `ResourceResponseFactory`.

    - Parameter action: Resource action.
    - Parameter path: Path associated with resource controller.
    - Parameter middleware: Route-specific middleware.
    - Parameter factory: Closure to instantiate a new instance of controller.
  */
  func addResourceAction<T: ResourceResponseFactory>(_ action: ResourceAction,
                                                      on path: String,
                                                   middleware: [Middleware] = [],
                                                      factory: () -> T) {
    switch action {
    case .index:
      get(path, middleware: middleware, respond: factory().index)
    case .new:
      get(path + "/new", middleware: middleware, respond: factory().new)
    case .show:
      get(path + "/:id", middleware: middleware, respond: factory().show)
    case .edit:
      get(path + "/:id/edit", middleware: middleware, respond: factory().edit)
    case .create:
      post(path, middleware: middleware, respond: factory().create)
    case .destroy:
      delete(path + "/:id", middleware: middleware, respond: factory().destroy)
    case .update:
      patch(path + "/:id", middleware: middleware, respond: factory().update)
    }
  }
}

// MARK: - Use

public extension RouteCollection {

  /**
    Uses routing controller on specified path.

    - Parameter middleware: Route-specific middleware.
    - Parameter factory: Closure to instantiate a new instance of controller.
  */
  func use<T: RouteMapper>(middleware: [Middleware] = [], factory: () -> T) {
    namespace("", middleware: middleware, build: factory().draw)
  }
}
