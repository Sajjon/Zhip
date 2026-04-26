//
// MIT License
//
// Copyright (c) 2018-2026 Open Zesame (https://github.com/OpenZesame)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//

import UIKit

extension Coordinating {
    /// Recursive ascii dump of this coordinator (and its child-coordinator
    /// tree, plus each navigation stack and any presented stacks) used by
    /// `description` for debugging.
    ///
    /// Please fix this ugly code for me... we want a nice ascii representation of the coordinator and its
    /// coordinator stack and navigation stack (both presented scenes and non presented scenes.),
    /// using an increasing indentation for each level of depth
    func stringRepresentation(level: Int) -> String {
        let indentation: String = [String](repeating: "\t", count: level).joined()

        func scenesFor(_ navCont: UIViewController?) -> String? {
            guard let navCont = navCont as? UINavigationController, !navCont.viewControllers.isEmpty else { return nil }
            return navCont.viewControllers.compactMap { $0 as? AbstractController }.map(\.description)
                .joined(separator: ", ")
        }

        let scenesString: String = {
            guard !(self is AppCoordinator) else { return ", " }
            let directScenes = scenesFor(navigationController) ?? ""

            var presentedScenes = ""
            if let presentedScenesString = scenesFor(navigationController.presentedViewController) {
                presentedScenes = "presented scenes: [\(presentedScenesString)]\n\(indentation)\t"
                if directScenes.isEmpty {
                    return presentedScenes
                } else {
                    presentedScenes = ", \(presentedScenes)"
                }
            } else if directScenes.isEmpty {
                return ""
            }

            return """
            , scenes: [
            \(indentation)\t\t\(directScenes)
            \(indentation)\t]
            """ + presentedScenes
        }()

        let children: String = childCoordinators.map { $0.stringRepresentation(level: level + 2) }
            .joined(separator: ", \n\t")

        let childrenString: String = {
            guard !childCoordinators.isEmpty else {
                return ""
            }

            let separator = scenesString.isEmpty ? "" : ", "

            return """
            \(separator)children: [\(children)
            \(indentation)\t]
            """
        }()

        return """
        \n\(indentation){
        \(indentation)\t\(type(of: self))(nc: \(navigationController.hashValue.description
            .dropFirst(12)))\(scenesString)\(childrenString)
        \(indentation)}
        """
    }
}
